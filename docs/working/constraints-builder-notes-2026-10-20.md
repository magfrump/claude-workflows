# Constraints-builder: notes from the second runs (2026-10-20)

The "Notes for the skill" sections from the second run in each of the four repos, copied verbatim from the author's files (`external/constraint-builder-skill/*.txt`, which is gitignored). They are the input to the skill revision on `feat/constraints-builder-rev2`.

# behemoth-arsenal

The provenance check reshaped the result more than any reader did. This repo's owner
commits as `Mitchell Owen`, and agents commit as `magfrump` with a `Co-Authored-By` trailer;
most answer files were committed (or last touched) by agents. A strict reading demotes almost
every owner quote to agent-written. The skill should say what to do when the answers path is
right but the commits are agents' — here it became a list in the ratify entry rather than a
demotion, which seemed proportionate for a sole-author repo.
Readers misfile line citations. One reader put three `answers-9-7-26.txt` quotes under
`answers-9-2-26.txt` (a 13-line file) at lines 99-108. `git blame` on a cited line catches this
for free; the skill could require a blame or `sed -n` of every author-text citation.
The current branch was not the default branch, and they differed in both directions: the
guidance the draft wanted to point at (five rules, R7) was on the branch only; the
`constraints-doc-missing` entry was on `main` only, so the branch's `next-id` would have
reissued Q-094. The skill says "next-id on fresh main" but not how to get there when merging
is not allowed; reading `main`'s copy by `git show` worked.
A merge of `main` into the working branch was refused by the harness ("Modify Shared
Resources"), so the questions entry is filed on the branch and will meet main's Q-094 entry in
the index block at merge time.
`zsh` does not word-split `$L`: a multi-path `rg` built from a variable silently searched
nothing ("No such file") and printed 0, which reads as a pass. The skill's planted-copy step is
what exposed it; a check that greps zero lines should be distrusted until planted.
Readers needed a size cap on reports. Seven reports of 10-20 KB each were the bulk of the
context cost; the brief could ask for at most N candidates per slice, ranked.
What the owner corrected (first reply): (a) a line the sources called hard on ~20
decisions was soft to the owner — the source count measured how often the rule was applied,
not what breaking it costs, which the skill already warns about and this run still missed;
(b) a repo-stated rule ("the AI never rolls") was stronger than the owner's stance — it came
from agent text citing itself, and no owner sentence backed it; the provenance pass should have
flagged a hard clause with no author source at all; (c) a soft line duplicated two hard lines —
a dedupe pass across hard and soft (does this line prune anything the hard lines don't?)
would have caught it.
Where the evidence was: the refuse-whole cluster was largest in `questions-settled.md` and
the decision log's Notes, as the first runs found; the owner's own words were thinner on design
rules than on game rules. Almost every author-text candidate was a game ruling (LOCAL).
# belegarth-herald

- **The existing `docs/constraints.md` was untracked and unparseable.** Step 0.1 assumes an
  existing file is the contract to amend. This one was an earlier agent draft, so amend mode
  would have kept IDs (`A1`, `C1`) that the grammar rejects. Suggest: "if the file is untracked
  or doesn't parse, treat it as evidence, not as the contract."
- **The default branch was behind the work.** The ADR that carries half the hard evidence was
  on the current, unmerged branch, and the DD was on main but not on the current branch. "Unmerged
  means proposed" is right, but the skill should say how to treat a branch that is about to merge
  (here: call 1). Running `next-id` on the current branch would have reissued Q-012. The
  "fresh main" instruction mattered; `git archive main docs/working` into a temp dir worked.
- **Provenance left nothing as author text.** Every commit, including the init commit that
  wrote `CLAUDE.md`'s train-in-place line, has a Claude co-author. The step 4 test then makes every
  rule agent-written. That is accurate, but it means the ratify entry carries all the weight.
- **Reader output:** Explore agents return their report through a hand-back tool, not the last
  text message. Pulling `.input` of the `SubagentHandback` tool_use from the transcript was the
  way to save each report to its own file.
- **The first draft of the H2 check hit legitimate code** (`MediaRecorder.AudioSource.*`).
  Running against today's tree before planting caught it, as the skill predicts.
- **Block boundaries:** the copy-ready block holds `# ` headings and H/S lines, so it can't sit
  inside a fence (the parser skips fences). A sentence naming its first and last heading marks it
  instead. A clearer template convention would help.
- **Bold list labels trip the parser.** `- **S1 (…)**` reads as an inexact ID after the marks.
  The first draft had seven of these in Sources; a pre-parse `rg` for ID-like line starts found them.
# claude-workflows

- **Amend mode had no step for "what did the last run skip".** Revision 2's sources doc read only records, log and DDs. The biggest yield this time came from the author's answers files and the archive, which the earlier run never opened. Step 0.1 should ask which slices the existing doc was built from.
- **Provenance by path misleads.** Four `docs/human-author/` files carry a Claude co-author trailer. The step 4 check caught this, and the reader brief's AUTHOR-PATH tag would have hidden it.
- **Evidence from loop outcomes is now available**, through the three research docs on the build-loop branches, and it was cheap to read. The skill does not name it as a source. It should: it shows which lines decide picks.
- **The existing doc carried the defect the skill warns about** (a preamble pointing at "Moved out" in a file without one). That is evidence the author pasted the block from a working doc.
- **Revision 2's success lines were mostly not runnable** ("security-reviewer reports no…", "the design names…"). Rewriting them as greps found a live contradiction (live-verify-gate's fail-open lines) within minutes.
- **The author's corrections:** they took the recommended reading on C1, C3 and the H3 clause, and dropped the one new line (removing over guarding) as practice. A candidate resting only on agent-written evidence was the one cut, which is consistent with the step 4 authority ranking.
- **The author moved a soft line out after reading the draft:** the S9 line (minimal revertable change, cheap step first, cut after repeated errors) failed the discrimination test on two of three clauses, but it passed both of the skill's earlier sorts (revision 2's and this run's). Clauses that trigger mid-review ("after repeated errors") are process. The sort in step 5 should test each clause for *when* it applies, not only whether designs could differ.
- **Recording the answers broke the parse once:** a list item beginning `- H3:` made the file unreadable (duplicate ID). The template's rule covers it, but writing answers back into the doc is the moment it bites.
- **`awk` with `{40}` is not portable** (mawk). The blame loop printed nothing until it was rewritten with `grep -E`. A silent empty result looks like "no author commits".

# philosophy-research

- **The decision log has no Notes column.** This repo's `log.md` is `Date | Decision | Rationale`; the reader mined Rationale. The brief and the source table name a "Notes column" as the main yield; they could say "the rationale or notes column".
- **An untracked `docs/constraints.md` is a case step 0 does not cover.** Step 0 says to amend an existing file, but this one was untracked, minutes old, and held content the author had already rejected. Asking which baseline to amend was the right move; the skill could say so: treat a file that is not on the default branch as a draft, and ask.
- **Amend mode on a working draft, not on `docs/constraints.md`.** The skill assumes amend means the committed file. Here the baseline was a prior working draft, so the diff is against that, and the ordering rule (by source count) fights the keep-the-IDs rule: the IDs now run H2, H4, H3, H5, H1, H6. The skill should say which wins.
- **Provenance changed the picture more than extraction did.** Four of the nine author files carry an agent co-author trailer, including the charter. Without the blame step the draft would have called them all the author's own. The author's answer was "mixed", which the skill has no label for; "transcribed" was used.
- **A planted test caught a wrong regex.** The first authority search required a character before `gh`, so a command at the start of a line went unseen. The plant step earned its cost on the first try. `--no-ignore` over the working tree hit only vendored code, which argues for scoping such checks to `git ls-files` rather than reporting the difference as a finding.
- **A literal in a success line can trip its own check.** The pass-1 privacy check embedded the author's address, so the committed constraints file would have matched it. Derive such values at run time (`git log -1 --format=%ae`).
- **The biggest finding was a missing rule, not a wrong one.** In-app coherence pruned options in four decisions and was absent from the 10-18 draft, because it conflicts with a later author answer. Readers that cluster by phrase family found it; the earlier topic-based pass did not.
- **The subagent hand-back form.** Readers returned their reports through a hand-back tool call, not a final text message, so saving "the final message" to a file needed the tool input, not the last text block.
- **The author overruled the "authority boundary" row of the taxonomy.** The reader brief files authority rules as instructions-file text *and* one hard criterion, so loops prune options that need the act. On 2026-10-20 the author called that project guidance, to be enforced in the instructions file and by tests, along with honest marks, gate honesty, theorem style, translation loss, negative controls, stable ids, live-docs hygiene, privacy and citation status. The bar the author applied is narrower than "could two designs score differently": a rule that tests or the instructions file can enforce does not belong here even if a design could fail it. Two hard lines left (divergence and additive change) are the ones a test cannot check before a design is chosen. The skill's taxonomy should add that test: "enforceable after the fact by a test or the instructions file" goes out.
- **The author reviewed the wrong file.** The review named pass-1 IDs from the untracked `docs/constraints.md`, not this draft. A draft sitting next to an untracked file that parses as the real one invites that; the hand-off should say plainly which file is the draft, and recommend removing the stale one.
- **Asked directly:** four calls by `AskUserQuestion` (in-app coherence, checked claims, provenance, spend). The author dropped in-app coherence for now, made checked claims soft rather than hard, called the co-authored files mixed, and kept spend behind questions entries.
