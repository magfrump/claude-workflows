# Code Review: Usage-Driven Prioritization

**Branch:** feat/r2-usage-driven-prioritization
**Reviewed:** 2026-03-23
**Status:** CONDITIONAL PASS

## Summary

A clean, well-structured script that parses JSONL usage logs and cross-references them against known skills/workflows directories to produce a ranked usage table. The test suite covers the main paths well. A few correctness issues need attention: empty `usage_data` produces a malformed output row, colon-containing names would be truncated by the awk parser, and loose grep assertions in tests could pass for wrong reasons.

## Findings

### Must Fix

| # | Finding | Location |
|---|---|---|
| R1 | **Empty `usage_data` produces garbage row.** If the log exists but contains no valid entries (no `.event`/`.name` fields), `usage_data` is empty. The `while read` loop on line 75 still executes once with empty variables, printing a malformed table row (`printf` with `%d` and empty string triggers an error or prints 0). Guard with `[ -n "$usage_data" ] &&` before the while loop. | `scripts/skill-usage-report.sh:75` |
| R2 | **Awk `split` on `:` truncates names containing colons.** The awk block on line 60-62 uses `split(k, parts, ":")` to recover event and name from the `event:name` key. Any name with a colon (unlikely but possible, e.g. `my:skill`) would be silently truncated to `my`. Use a different delimiter (e.g. `\x1f` unit separator) for the internal key. | `scripts/skill-usage-report.sh:55-62` |

### Must Address

| # | Finding | Location | Author note |
|---|---|---|---|
| A1 | **No `jq` dependency check.** The script requires `jq` but does not verify it is installed. Under `set -e`, a missing `jq` produces a confusing "command not found" error on line 53. Add a guard like `command -v jq >/dev/null 2>&1 \|\| { echo "Error: jq is required"; exit 1; }`. | `scripts/skill-usage-report.sh:53` | -- |
| A2 | **Loose test assertion: `grep -q "3"` matches timestamps.** The assertion `echo "$output" \| grep -q "3"` on line 52 of the test file would match `2026-03-23` in the Last Used column, not necessarily the count column. This test would pass even if the count were wrong. Use a more specific pattern like `grep -q '\b3\b'` or match the full row structure. | `test/scripts/skill-usage-report.bats:52` | -- |
| A3 | **Tests use `output=$(bash "$SCRIPT")` instead of BATS `run`.** Every test captures output manually rather than using the idiomatic `run bash "$SCRIPT"` / `[ "$status" -eq 0 ]` pattern. This means (a) a non-zero exit code silently fails the test for the wrong reason, and (b) BATS cannot display captured output on failure, making debugging harder. | `test/scripts/skill-usage-report.bats` (all tests) | -- |

### Consider

| # | Suggestion |
|---|---|
| C1 | **Add a test for malformed/mixed JSON lines.** Real log files may contain partial writes or lines missing `.event`/`.name`. A test with a mix of valid and invalid lines would verify the `jq select()` filter handles this gracefully. |
| C2 | **Add a `--help` / `-h` flag.** Even a one-liner usage message makes the script more discoverable for future contributors. |
| C3 | **The `all_known` array construction on line 35 uses the `${arr[@]+"${arr[@]}"}` workaround for bash <= 4.3.** Consider adding a brief comment explaining why, since this idiom is not widely known. Alternatively, if the project targets bash 4.4+, the simpler `"${arr[@]}"` on an empty array is safe. |
| C4 | **Consider machine-readable output.** A `--json` or `--tsv` flag would make it easier to pipe this into other scripts (e.g., the self-improvement pipeline). The current fixed-width table is human-friendly but hard to parse programmatically. |
| C5 | **Empty skills/workflows directories.** If both directories are empty or missing, and the log has data, the script works but the "Never invoked" section is silently absent. This is correct behavior but a brief note in the script header or `--help` output would clarify the cross-reference expectation. |

## What Works Well

- **Clean separation of concerns**: log parsing, table output, and never-invoked detection are distinct sections with clear comments.
- **Good testability via environment variable overrides**: `USAGE_LOG_FILE`, `SKILLS_DIR`, and `WORKFLOWS_DIR` make the script fully testable without touching real user data.
- **Graceful degradation**: missing and empty log files are handled with informative messages rather than errors.
- **Test coverage hits the important cases**: frequency ranking, never-invoked detection, mixed event types, unknown skills, empty/missing logs.
- **The `setup`/`teardown` pattern in tests properly isolates each test** with fresh temp files and directories.
- **The jq + awk pipeline is efficient**: single pass through the log file, no temp files, proper use of associative arrays for aggregation.
