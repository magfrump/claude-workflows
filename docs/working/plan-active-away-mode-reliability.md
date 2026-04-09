# Plan: Active/Away Mode Reliability

## Scope
Fix /active and /away mode switching reliability through clearer CLAUDE.md wording and explicit behavioral contracts.

## Approach
Rewrite the Operating Modes section of CLAUDE.md to: (1) support multiple invocation patterns so the mode switch reaches the model regardless of Claude Code's command parsing, (2) add an explicit acknowledgment protocol, (3) define precise behavioral contracts for each mode, and (4) document the platform limitation about slash commands.

## Steps

### Step 1: Rewrite Operating Modes section in CLAUDE.md (~60 lines replacing ~25 lines)

Replace lines 62-87 of CLAUDE.md with:

- **Multiple trigger patterns**: Accept "You are in /away mode", "/away", "away mode", or mode set as preamble — so the user isn't dependent on a single syntax
- **Explicit acknowledgment protocol**: When Claude detects a mode switch, it must respond with a confirmation stating the new mode and key behavioral changes
- **Precise /active behavioral contract**: Enumerate exactly which actions require user approval (commits, pushes, PR creation, plan implementation) vs. which are autonomous (file reads, edits, searches, running tests)
- **Precise /away behavioral contract**: Same enumeration but with the autonomous set expanded
- **Mode persistence**: Instruction to treat mode as session-scoped, default to /active if uncertain
- **Platform limitation note**: Brief note that `/active` and `/away` may not work as standalone messages if Claude Code intercepts them as unknown commands — recommend including them in a sentence

### Step 2: Commit and push

## Size estimate
~60 lines of markdown replacing ~25 lines. Single file change.

## Test specification
This is a documentation-only change. Testing is observational:
| Test case | Expected behavior | Level | Diagnostic expectation |
|-----------|------------------|-------|----------------------|
| User types "You are in /away mode" | Claude acknowledges mode switch explicitly | manual/observational | Claude's response includes mode confirmation |
| User types "/away" in a message | Claude recognizes mode switch | manual/observational | Claude's response includes mode confirmation |
| User returns and types "/active" | Claude summarizes autonomous work and confirms /active mode | manual/observational | Summary of commits, decisions, flagged items |
| Long session with context compression | Claude defaults to /active when mode is uncertain | manual/observational | Claude asks for confirmation rather than assuming /away |

## Risks
- The hypothesis predicts "consistent mode-switching behavior within 2 rounds." This depends on Claude Code's command parser behavior, which we cannot control. If `/away` as a standalone message is consumed by the parser, the user will need to use alternative phrasings, which the new docs explicitly support.
- Over-specifying the behavioral contract could make the section too long and reduce compliance. Kept to a focused list format.
