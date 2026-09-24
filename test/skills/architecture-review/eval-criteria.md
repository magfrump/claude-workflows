# Architecture Review — Evaluation Criteria

One planted structural defect per fixture, plus two clean negatives. Each fixture is
a single file (the generator copies it alone into a throwaway repo), so module
boundaries are conveyed in-file: a header comment states the intended layering, and
`---- file: <path> ----` markers split the file into the modules a real repo would
hold separately. The header describes the architecture only; it never points at the
violation.

## Fixture → Expected Finding Map

| Fixture | Planted defect | Expected Severity | Must Mention |
|---|---|---|---|
| tc-arch1-domain-imports-infra.py | Domain `PricingService` imports and constructs `PostgresDiscountTable` (domain → infrastructure) | Structural | dependency direction / inversion, domain depending on Postgres/infrastructure |
| tc-arch2-circular-modules.ts | `customers` imports `billing` (balance check) while `billing` imports `customers` (email lookup) | Structural | circular / cyclic / mutual dependency |
| tc-arch3-god-class.py | `AccountService` owns auth, sessions, mail, billing, PDFs, CSV export, stats, flags, audit log | Structural or Coupling | single responsibility / god class |
| tc-arch4-fat-interface.py | 15-method `BlobStore` port; clients use 2; read-only adapter stubs 12 with `NotImplementedError` | Coupling or Minor | interface segregation, interface too broad, `NotImplementedError` stubs |
| tc-arch5-leaky-gateway.py | `PaymentGateway` port returns `stripe.PaymentIntent`; use case catches `stripe.error.CardError` and reads charge risk fields | Coupling or Structural | leaky abstraction, vendor/Stripe types crossing the port |
| tc-arch6-clean-ports-adapters.py | None — ports in application, adapters in infrastructure, wiring in a composition root | no Structural/Coupling | — (full report must pass the format suite) |
| tc-arch7-internal-fix.patch | None — bug fix confined to a private `_ttl_for` body plus private constants | no Structural/Coupling/Minor | Scope Check skip note ("Skipped", "implementation-only") |

## How to Use

1. `bash test/skills/generate-reports.bash architecture-review` (spends model compute)
2. `bats test/skills/architecture-review-eval.bats`
3. `format_check` runs `architecture-review-format.bats` on arch1, arch6 and arch7
   (arch7 exercises the suite's skip-note tests).

## Notes

- Tiers follow the SKILL.md scale. arch3 allows Coupling because the skill's
  "Minor = SRP stretch / Structural = responsibility fundamentally misplaced" line
  leaves a nine-responsibility service between the two definitions it names.
  arch4 allows Minor because "interface could be narrower" is listed under Minor
  while "interface too broad" is under Coupling. arch5 allows Structural because
  the application layer importing the vendor SDK is also a layer-boundary break.
- arch3 also puts SQL/SMTP/Stripe calls in the application layer; that is part of
  the same god-class defect, not a second planted one.
- arch7 is a patch rather than source because the skip path is defined over a
  diff; the single-commit fixture repo has no `main` to diff against, which is why
  the runner prompt names the file as the change under review.
- `cites_pattern` values are permissive alternations; they must not contain `;`.
