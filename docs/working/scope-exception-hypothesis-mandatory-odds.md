# Scope Exception: hypothesis-mandatory-odds

## File needing modification outside allowed scope

**File:** `scripts/lib/si-functions.sh`
**Function:** `validate_task_json()` (line 21–89)

## Reason

The `odds_ratio` field is now mandatory in the task-generation prompt, but the
schema validation function in `si-functions.sh` does not enforce it. Without a
corresponding validation rule, a task that omits `odds_ratio` will still pass
the schema gate — the field is only "mandatory" by prompt instruction, not by
code enforcement.

## Recommended change

Add a validation check in the `validate_task_json` jq check block:

```jq
elif (.odds_ratio | type) != "string" or (.odds_ratio | test("^[0-9]+:1 (for|against)$") | not)
then "odds_ratio must match format 'N:1 for' or 'N:1 against'"
```

## Risk of not making this change

Low-to-medium. The LLM prompt is explicit about the format, so most generated
tasks will include it. But without schema enforcement, occasional omissions
will silently pass validation and produce `—` in the hypothesis log instead of
real odds data, reducing calibration data quality.
