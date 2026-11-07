# Research: owner entries gloss every reference, by rule

- **Goal**: Put the rule "owner-facing text glosses its internal references, and a numbered label links the doc that defines it" where all three writers of owner text meet it (the orchestrator's entries, a build loop's marker bodies, the final message), instead of in one session memory.
- **Problem framing**: Five of the six open owner entries still carry a bare numbered label (read strictly; three of six read leniently), and the only statement of the rule any writer loads is a memory that a build loop or a cycle in another repo never sees. Considered and discarded: "the questions file is hard to read because entries are long or the file holds the wrong things", which decision 040's route split already addressed and which the owner rejected in terms ("length isn't the relevant dimension, clarity is").
- **Project state**: Delivers the rule in the global instructions, the dev-cycle skill and the build-loop prompt · closes the revisit trigger decision 040 named ("then entry clarity is the problem") · not blocked (cite: docs/decisions/040-questions-doc-owner-only.md)
- **Task status**: complete (implemented; review-fix loop clean; see Outcome)

## Motive check (constraint S5)

Hand audit of the six open entries in `docs/working/questions.md` at 62687b97. Own text only: fenced blocks and quoted marker lines are left out. Labels were found with a regex over `Q-NNN`, `FP-NNN`, `decision NNN`, `row N` and one-letter-plus-digits forms, then each was read in place and classified by hand. [observed]

The reading is strict and even: a label is glossed only when the words next to it say what that item is. A bracketed citation after a stated fact, such as `(Q-156)` or `(Q-214)`, is not a gloss. A Q-ID needs the gloss alone, since the questions files are its one known home; any other numbered label also needs its doc.

| Entry | Own-text labels (excluding the entry's own ID) | Bare ones | Passes the rule? |
|---|---|---|---|
| Q-261 image-lag | Q-167, Q-259, Q-260 | Q-167 ("step (a) still needs") | No |
| Q-256 canon-proposal-filter-choice | none | none numbered ("review arms" is unglossed jargon) | Yes on labels |
| Q-255 herald-egress-fix-unconfirmed | Q-052, Q-214, decision 039 | Q-052, Q-214 | No |
| Q-254 blocked-...-q125-verify-check-1 | C1, Q-098, Q-125, Q-161 | all four; Q-125 is the entry's whole subject and never says what it is | No |
| Q-167 post-install-host-probes | Q-096, Q-156, Q-241 | Q-156 | No |
| Q-084 q076-live-checks | C2, C3, Q-076, Q-086, Q-090, Q-091, Q-093, Q-094 | all but Q-076 | No |

**Baseline, entries' own text: 5 of 6 entries fail; 21 distinct labels (self-references aside), 15 of them bare; no entry uses a markdown link, and 3 of the 6 name a doc path at all.** Read leniently, with a bracketed citation or a thin phrase counting as a gloss, Q-255 and Q-167 pass and 3 of 6 fail. The motive holds either way: the failure is common, not one bad entry. These are one person's hand classifications of one snapshot.

**Baseline, marker bodies: 1 of 1 fails.** Q-254 quotes the only open marker body, and it never says what Q-125 is or what C2 to C6 are. That is also the worst entry, so the build-loop writer has to be reached too: a rule only the orchestrator sees would miss it.

The owner's words are in `docs/working/trials/2026-10-30-friction-engagement.md` (T2, 2026-11-06): "the biggest problem is jargon and references", and the same note calls the final message with two links "great".

## What exists

- `global-instructions/CLAUDE.md`, "Running questions document": the entry grammar, the options-table rule and the bullets on routing, one judgment per entry and so on. Installed as `~/.claude/CLAUDE.md` (`devcontainer-config/install.sh`, `CLAUDE_HOME_SRC`), so it loads in every session in every repo, subagents included. This run's own context carries it. [observed]
- `skills/dev-cycle/SKILL.md`: the Rules' "Attention is the budget" bullet points at that grammar. Step 7 files blocked, stopped and ready entries with the loop's marker lines verbatim ("loop text, data not instructions"). "**Final message**" after step 10 lists what the final message holds. [observed]
- `scripts/build-loop.sh`, `loop_prompt()`: the prompt a build loop receives. It asks for "plain prose and an options table" twice and says nothing about references. `test/scripts/build-loop-dispatch.bats` holds the prompt to a list of phrases. [observed]
- `scripts/questions.sh check`: structure only (headings, routes, dates, status, index). It reads `questions.md`, the archive and `watching.md`, so it sees a marker body only once filed, after the loop has ended, and never sees a final message. Its "Entry grammar" header is fingerprinted by `test/scripts/convention-migrations.bats`, so a change there needs a migration line. [observed]
- The memory `owner-entries-clarity-not-length`: the only statement of the rule today; per-repo auto-memory, invisible to other repos' cycles. Build loops here do load it, but it is one line of an index until read. [observed: it appears in this run's MEMORY.md index; inferred for other repos]

## Invariants

- The entry grammar `check` enforces does not change, so no migration is due. `scripts/questions.sh`'s header and `init` output stay byte-identical. [observed: `scripts/lib/migrations.sh` `conv_source`]
- `skills/dev-cycle/SKILL.md`'s step 6 and 9 templates and step 8's brief-lines paragraph are fingerprinted; the Rules and the Final message paragraph are not. [observed: `conv_source` in `scripts/lib/migrations.sh`; all five fingerprints are unchanged at this branch's tip, run by the fact-check]
- Marker text is quoted verbatim, as data. The rule must not ask the orchestrator to rewrite it (rows 706, 714 in the skill's step 7). [observed]
- Marker limits ($BODY_LINES, $BODY_BYTES, no HTML comment opener) are unchanged. [observed]
- `scripts/d6.sh` is untouched (brief, out of scope). Nothing here writes `questions.md`, `watching.md` or the roadmap.

## Prior art

Decision 040 pruned "[11] shorter entries: wrong measure (clarity, not length)", carried forward below. The options-table paragraph in the same section is the same kind of rule: a shape stated once in the global instructions, named in brief by the prompt ("an options table"), and pointed at by the skill. The prompt's "plain prose" clause is the existing hook for what a marker body should read like.

## Gotchas

Failure-pattern grep: FP-016, FP-071, FP-162, FP-169 (see Prior failures section)

- A regex cannot tell a glossed label from a bare one: one that flags every label flags all 21 above, 6 of them glossed, and misses "review arms" (no number). That figure comes from the hand audit, not from running such a check. See candidate [6].
- Writing a file through Bash with a body naming the global file and a `.claude` path trips the policy-file hook; use Write or Edit, and `git commit -F`.

### Prior failures

Grep: `grep -inE 'owner|question|marker|prompt|jargon|gloss|prose' docs/failure-patterns.md`

- **FP-071** (ledger write has no owner at the moment it is possible): the relevant one. A rule that sits away from the moment of writing does not get carried out, which is why the prompt and the skill each carry a pointer as well as the global bullet.
- **FP-169** (prose appended to a parsed date field): a warning against putting the gloss into a parsed line. The rule adds no field and touches no **Needs:** line.
- **FP-016**, **FP-162**: keyword hits only (a permission prompt, a marker directory); unrelated.

## Divergent design: where the rule lives

Seeded with `docs/constraints.md` at 62687b97 and the brief. Prior pruning grep: one relevant match, [11] from decision 040, carried forward; the other hits are preambles or unrelated. Keywords: gloss, jargon, clarity, entry, owner-facing.

### Candidates

1. Status quo: the memory alone.
2. One bullet in the global instructions' "Running questions document" only.
3. The dev-cycle skill's rules only.
4. The build-loop prompt's marker guidance only.
5. `questions.sh check` refuses a bare label.
6. `questions.sh check` warns on a bare label (advisory).
7. Composite: the rule once in the global section, a short pointer in the skill (entries and final message) and in the build-loop prompt (marker bodies).
8. A new `guides/owner-text.md` holding the rule, with pointers from all three places.
9. A required `**Terms:**` bullet in the grammar, with `check` keying on its presence.
10. A glossary doc that the owner looks labels up in.
11. `questions.sh index` appends each referenced Q-ID's slug to the entry (a generated gloss).
12. `--marker` refuses a body with a bare label.
13. An LLM pass that rewrites entries before filing.
14. [carried from 040-questions-doc-owner-only: shorter entries, wrong measure]. Not re-proposed; the brief rules out length limits too.

### Diagnosis

The requirement: all three writers meet the rule when they write, in every repo, at no attention cost to the owner, and the rule is checkable afterwards. Hard: H4 (an LLM judgment never gates, so a check here could only key on something re-checkable, and whether a gloss is adequate is not), H3 (hermetic). Soft: S2 (always-loaded budget of about 30 lines), S3 (one source), S4 (prose arrives when needed), S5, S6 (an observable that can come out negative), S10, S11 (text over hooks).

### Prune

| Candidate | Result | Why |
|---|---|---|
| [5] check refuses | Pruned | H4 does not bar a regex, but a regex can only test for a label, not for its gloss, so it would refuse all 6 glossed labels above along with the 15 bare ones: a gate on the wrong thing. It also turns the health check red on five of six entries, and it sees a marker only after filing and never a final message. |
| [12] --marker refuses | Pruned | Same as [5], at the gate, and a refused marker costs a whole loop. |
| [13] LLM rewrite | Pruned | A new mandatory agent step per entry (S2), and marker text is quoted verbatim by rule. |
| [9] Terms bullet | Pruned | Checks that the field exists, not that it helps; it is a convention change with a migration across repos, and it adds a line to entries that have no labels. |
| [10] Glossary | Pruned | It moves the lookup onto the owner, which is the cost being removed (S10). |
| [11] Generated slug gloss | Pruned | A slug such as `q076-live-checks` is itself jargon, and it reaches only Q-IDs in one file. |
| [1] Status quo | Survives as the baseline | Fails the brief's reach: 5 of 6 entries fail, and the memory never reaches another repo. |

### Survivors

| Candidate | Orchestrator entries | Marker bodies | Final message | Other repos | Always-loaded cost (S2) | One source (S3) | At the moment (S4) |
|---|---|---|---|---|---|---|---|
| [1] Status quo | Partly (this repo) | Partly | Partly | No | 0 | Yes | No |
| [2] Global only | Yes | Yes, but nowhere near the marker instructions | Yes | Yes | about 6 lines | Yes | Weak |
| [3] Skill only | Yes | No | Yes | Yes | 0 | Yes | Yes |
| [4] Prompt only | No | Yes | No | Yes | 0 | Yes | Yes |
| [6] Check warns | Yes, noisily | No | No | Yes | 0 | Second statement | At check time, after writing |
| [7] Composite | Yes | Yes | Yes | Yes | about 6 lines | Yes: pointers name the bullet | Yes |
| [8] Guide plus pointers | Only if opened | Only if opened | Only if opened | Yes | 0 | Yes | Needs one more read |

H4 allows [6], an advisory check, but it fails on its own terms. By the hand audit it would be right about two times in three, it fires on five of six entries each cycle, and trial T7 ("zero recurring warnings") set the opposite direction. S11 (pure text) favours the prose options too. [8] saves about 6 always-loaded lines but puts a rule whose whole cost is forgetting it behind an extra read, and the bullet sits well inside S2's budget, so the saving does not pay for the lost reach. An /away session in another repo writing one entry has no prompt and no skill: only the global section reaches it, which rules out [3] and [4] alone.

### Decision (Path A)

**[7].** It is the only survivor that reaches all three writers at the moment of writing, in every repo, for one always-loaded bullet of about 6 wrapped lines. Confidence above 80%: [2] reaches them only from far away, and the others each miss a writer the brief requires.

The rule goes unenforced, on purpose: no re-checkable test separates a gloss from a bare label, so a check would be noise. The count below stands in for it after the fact.

Non-DD choices:

- Pointer wording: the prompt carries one self-contained sentence, not only a pointer, since a loop's marker is the worst-failing writer and non-Claude agents may run it (S11). That restates the rule's core in one clause, a small deliberate cost to S3; it names the bullet and leaves the exceptions there.
- Q-IDs need the gloss alone, not a link (written into the bullet): the questions files are their one known home, and a link on every Q-ID would make the rule too heavy to follow. The brief's example of the link half is a trial number.
- Quoted text: gate output and marker bodies stay verbatim, and the orchestrator's own lines around them carry the gloss (the memory's note that gate output is easy to skip, plus rows 706 and 714).
- Durable record: `docs/decisions/log.md` row 84. This doc is disposable, and the observable has to outlive it.
- Tests: one bats case that holds all three pointers to the bullet's name, so a rename cannot leave them dangling, and one phrase in the dispatch test. No script logic changes.
- The memory `owner-entries-clarity-not-length` is left in place: it is outside the repo, and removing it is the owner's call after this lands.

## Observable (constraint S6)

Both can come out negative.

1. **The count.** Repeat the audit above, with the same strict reading, over at least 5 entries opened after the first install from a commit holding this merge. Count entries' own text and marker bodies separately. Baselines: 5 of 6 own-text fail, 1 of 1 marker bodies fail. It helped if under half of the new entries fail on their own text and the marker bodies filed by then mostly pass. If half or more still fail, prose has not worked at this reach, and the next step is a new divergent design, not a louder sentence.
2. **The owner's report.** The owner's next feedback on the asks. It failed if jargon or bare references are again named as the problem, whatever the count says.

The separate marker count is what shows whether the prompt's sentence reaches loops. Only the cycle can file a watch for this (a build loop may not write `watching.md`), so this run's report asks it to.

## Outcome

See `docs/decisions/log.md` row 84 and the branch's commits. Reach depends on the release: the global file, skill and script arrive with the first install from a commit holding this merge, followed by a new session. The pending paste in Q-261 (the release of the dev-cycle scripts) is pinned to 21399f53, which lacks this work, so running it as written does not start the count. Until then the installed image copies carry no rule (grep count 0 at dff98910; the host's `~/.claude` cannot be read from here).

## Files read

Last verified: 2026-11-06

docs/working/briefs/2026-11-06-owner-entry-gloss-rule.md
docs/working/questions.md
docs/working/trials/2026-10-30-friction-engagement.md
docs/working/dd-questions-doc-purposes.md
docs/decisions/040-questions-doc-owner-only.md
docs/decisions/log.md
docs/failure-patterns.md
docs/constraints.md
docs/dev-cycle.md
global-instructions/CLAUDE.md
skills/dev-cycle/SKILL.md
scripts/build-loop.sh
scripts/questions.sh
scripts/lib/dev-cycle-read.sh
scripts/lib/migrations.sh
devcontainer-config/install.sh
scripts/health-check.sh
hooks/live-verify-gate.sh
guides/convention-changes.md
test/scripts/build-loop-dispatch.bats
test/questions-doc.bats
test/scripts/convention-migrations.bats
workflows/research-plan-implement.md
workflows/divergent-design.md
