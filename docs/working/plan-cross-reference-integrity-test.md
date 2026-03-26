# Plan: Cross-Reference Integrity Test

## Research Summary

### Link patterns found in markdown files

1. **Explicit markdown links**: `[text](../path/to/file.md)` — relative paths using `../` from subdirectories
2. **Bare path references**: `workflows/foo.md`, `skills/bar.md` etc. — root-relative paths appearing in prose or backtick-quoted
3. **Anchor links**: `[text](#section)` — internal links, out of scope (not file references)

### Scope

Files to scan: all `.md` files in `workflows/`, `skills/`, `guides/`, `patterns/`

Two extraction strategies:
- **Markdown links**: Extract path from `[...](path)`, skip URLs (http/https), skip anchors (#)
- **Bare paths**: Match `(workflows|skills|guides|patterns)/[filename].md` anywhere in line text

### Resolution

- Markdown links use relative paths (`../patterns/foo.md`), so resolve relative to the source file's directory
- Bare paths are root-relative, resolve from repo root

## Implementation Plan

### File: `test/cross-reference-integrity.bats`

1. `setup()` — set `REPO_ROOT` to `$BATS_TEST_DIRNAME/..`
2. Helper `resolve_link()` — given source file and link target, resolve to absolute path
3. Helper `collect_markdown_files()` — find all .md files in the 4 directories
4. Test: "all explicit markdown links resolve to existing files"
   - For each .md file, extract `[...](path)` links
   - Skip http/https URLs and anchor-only links (#...)
   - Resolve each path relative to source file directory
   - Assert file exists
   - Collect all failures and report at end
5. Test: "all bare path references resolve to existing files"
   - For each .md file, extract `(workflows|skills|guides|patterns)/[^ )\`]+\.md` patterns
   - Resolve from repo root
   - Assert file exists
   - Collect all failures and report at end
