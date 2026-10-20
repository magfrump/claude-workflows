# Working doc template

The working doc is `docs/working/constraints-draft-YYYY-MM-DD.md`. **The whole file must pass
`build-loop.sh --check-constraints`**, so:
- only the copy-ready block holds `H<n>:` and `S<n>:` lines;
- elsewhere, refer to a line as "the H2 line" mid-sentence, and never start a line (or a list
  item, or a table cell) with an ID;
- put each hard line's `success:` line directly under it, before any `#` heading;
- start no line with `<` (the reader takes it for raw HTML and refuses the file), and use no
  `[label]: url` reference links.

Remove the guidance in angle brackets when you write the doc.

```markdown
# Constraints draft: <repo> (<date>)

Input for the author, not the constraints doc. Copy the block below into
`docs/constraints.md` once the calls are settled; the rest of this file is the evidence.

- **Mode:** extraction | interview only | amend — <why>
- **Read:** <slices, file counts and sizes, branches and refs read off-tree>
- **Parsed:** `<the exact --check-constraints line>` (or: unparsed, because <reason>)
- **Citations:** file:line with quotes. <Which were spot-checked, and which were not.>
- **Cost:** every line below rides in every loop prompt. This draft has <N> lines.

## Copy-ready block

<Ordered by independent source count. A short preamble that stands alone once pasted:
what the doc is for, and where non-design rules live (only if that is already true).>

H1: <statement>
success: <observable>

S1: <statement>

## Sources

<One subsection per line, named in prose (the H1 line), never starting with the ID.>

### The H1 line — <n> decisions, <n> log rows, <n> DDs
- `docs/decisions/007-x.md:41` — "<quote>" (cited as the reason for pruning B)
- Narrowed by: <later decision, if any>
- Today: <success check run, result>

## Findings

<Rules the repo implies that do not hold today (violations found), dead revisit triggers,
records with no revisit section. Each is a finding, not a constraint.>

## Against existing guidance

What the instructions file and review guidance already say, in three lists: rules the
decisions imply that no guidance states, rules stated and confirmed by the decisions, and
rules stated but contradicted by later decisions or the code. Only the first list adds
anything; the last is a finding for the author.

## Calls for the author

| Call | Where the sources disagree | Interim reading in the block | If you choose otherwise |
|---|---|---|---|
| C1 <name> | <source A vs source B, cited> | <what the draft assumes> | <which lines change> |

<Also the interview questions for the top hard lines: does the wording match your stance;
what has it cost you; is it design or practice?>

## Moved out

| Rule | Kind | Enforced today by | Proposed home | Paste-ready text |
|---|---|---|---|---|

<Check the target file first. Mark "already covered" instead of proposing a duplicate.>

## Left out

| Candidate | Why left out | Sources |
|---|---|---|

## Superseded

| Earlier rule | Replaced by | Citation |
|---|---|---|

## Notes for the skill

For the constraints-builder skill's next revision, not for the author's doc. Record what
surprised you, any step that misled you or cost time for nothing, where the evidence actually
was, and (after the author replies) what the author corrected and why.
```
