# Plan: Self-Discovering Repo Health Check

## Checks

1. **Skill YAML frontmatter** — glob `skills/*.md`, extract YAML between `---` delimiters, validate `name` and `description` fields exist
2. **Workflow cross-references** — extract workflow filenames from CLAUDE.md/AGENTS.md/GEMINI.md, verify each exists in `workflows/`
3. **MD file consistency** — compare workflow sets referenced across CLAUDE.md/AGENTS.md/GEMINI.md, flag differences
4. **Skill cross-references** — extract skill names mentioned in MD files, verify each exists in `skills/`
5. **Fixture ↔ expected-verdicts** — for each `test/skills/*/fixtures/*`, check it has a corresponding entry in the sibling `expected-verdicts.bash`
6. **BATS tests** — run `bats test/skills/*.bats` (skip if no report outputs exist)
7. **shellcheck** — run shellcheck on all `*.sh` and `*.bash` files found via glob

## Design decisions

- All file discovery via globs — no hardcoded lists
- Aggregate pass/fail with non-zero exit on any failure
- Each check is a function that prints results and sets a global fail flag
- Colored output (green pass, red fail, yellow warn)
- No external dependencies beyond shellcheck and bats (both already installed)
