# API Consistency Reviewer — Evaluation Criteria

Synthetic fixtures, one planted inconsistency each (plus one clean negative),
spread across the surface kinds `skills/api-consistency-reviewer/SKILL.md` names.

## Fixture shape

`generate-reports.bash` copies each fixture **alone** into a throwaway repo, so a
fixture must carry its own baseline. Each file holds several pre-existing sibling
surfaces that establish the convention, plus the new surface fenced by
`BEGIN CHANGE UNDER REVIEW` / `END CHANGE UNDER REVIEW` comment lines. The runner
prompt tells the model to treat the fenced block(s) as the diff and the rest of the
file as the baseline. Fixture slugs name the domain, never the defect, because the
model sees the filename.

## Fixture → Expected Finding Map

| Fixture | Surface | Planted defect | Expected Severity | Must Mention |
|---|---|---|---|---|
| tc-api1-invoices-routes.ts | REST handler (Express) | Divergent pagination: `page`/`per_page` + `{items,total}` vs siblings' `limit`/`cursor` + `{data,next_cursor}` | Inconsistent | `cursor`; `per_page`/page-based/offset |
| tc-api2-billing-handlers.py | REST handler (Flask) | Divergent error shape: `{success,error_message}` vs `error_response()` → `{error:{code,message}}` | Inconsistent (Breaking accepted) | `error_message`; `error_response`/envelope/error code |
| tc-api3-client-sdk.ts | SDK methods | Verb drift: `fetchTeam` vs `getUser`/`getProject` | Inconsistent (Minor accepted) | `fetchTeam`; a `get<Noun>` neighbor |
| tc-api4-deploy-cli.py | CLI flags | Case drift: `rollback --dry_run` vs `--dry-run` on `deploy`/`scale` | Inconsistent (Minor accepted) | `dry_run`; `dry-run`/kebab |
| tc-api5-worker-config.go | Config schema | Breaking change disguised as addition: new `dead_letter_queue` key is required with no default, so every existing `worker.yaml` fails `Load` | Breaking | the key; default/optional/existing configs |
| tc-api6-order-events.ts | Event payload | Field drift: `timestamp` (epoch ms number) vs `occurred_at` (ISO-8601 string) on every sibling event | Inconsistent (Breaking accepted) | `occurred_at`; `timestamp`/epoch |
| tc-api7-webhooks-api.py | REST request/response (FastAPI) | Request/response asymmetry: `target_url`/`event_types` in, `url`/`events` out; siblings echo request names | Inconsistent | `target_url`; asymmetry or `event_types` |
| tc-api8-storage-client.py | Exported library functions | **Clean negative** — `get/list/delete_object` mirror `get/list/delete_bucket` (verbs, kw-only `prefix`/`page_size`, `NotFoundError`) | no Breaking/Inconsistent finding | a bucket neighbor (evidence of the survey) |

## Severity notes

- Tiers follow the skill's scale: **Breaking** only when existing consumers break.
  tc-api5 is the one fixture where that is unambiguous — existing config files are
  the existing consumers.
- tc-api2 and tc-api6 accept Breaking because a shared client error parser, or an
  event consumer that reads `occurred_at` for every `OrderEvent`, fails on the new
  surface; a reviewer can reasonably call that consumer breakage.
- tc-api3 and tc-api4 accept Minor: both are naming-only drifts with a clear precedent,
  where the skill's scale leaves Inconsistent vs "small deviation from convention"
  to judgment.
- The clean negative allows Minor/Informational observations; only Breaking or
  Inconsistent counts as a false positive.

## How to Use

1. `bash test/skills/generate-reports.bash api-consistency-reviewer` (spends model compute)
2. `bats test/skills/api-consistency-reviewer-eval.bats`
3. tc-api1 and tc-api8 also run `api-consistency-reviewer-format.bats` on the report
   (`format_check`).
