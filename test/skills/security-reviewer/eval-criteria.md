# Security Reviewer — Evaluation Criteria

Synthetic fixtures, one planted defect each, drawn from well-known weakness
classes that SKILL.md's cognitive moves target (trust boundaries, access
control, error paths, serialization, randomness). Two clean negatives look
suspicious at a glance but are safe; they test false positives.

## Fixture → Expected Finding Map

| Fixture | Defect (class) | Expected Severity | Must Mention |
|---|---|---|---|
| tc-sec1-sql-injection.py | `?sort=` f-stringed into `ORDER BY` while other values use placeholders (CWE-89) | Critical or High | SQL injection, or an allowlist of sort columns |
| tc-sec2-missing-ownership-check.ts | `GET /invoices/:id` authenticates but never scopes to `req.user.orgId` — IDOR (CWE-639) | Critical or High | IDOR / ownership / org or tenant scoping |
| tc-sec3-path-traversal.go | `?file=` passed to `filepath.Join`; `../` escapes the per-user export dir, `.csv` suffix check doesn't stop it (CWE-22) | Critical or High | traversal / `../`, or a containment fix (`filepath.Rel`, `IsLocal`, prefix check) |
| tc-sec4-fail-open-auth.go | Token introspection error or timeout logs and calls `next` without a principal — fail-open (CWE-636) | Critical or High | fail-open / fail closed / deny on error / bypass |
| tc-sec5-predictable-reset-token.js | Password-reset token built from `Math.random()` (CWE-338) | Critical or High | a CSPRNG (`crypto.randomBytes`, `getRandomValues`, `randomUUID`) or predictability |
| tc-sec6-unsafe-deserialization.py | `pickle.loads` on a base64 client cookie (CWE-502) | Critical | remote/arbitrary code execution |
| tc-sec7-clean-dynamic-query.ts | **Clean.** SQL built by string concatenation, but columns come from an allowlist map, direction is a ternary, all values are `$n` placeholders | no Critical/High | — |
| tc-sec8-clean-exec.go | **Clean.** `exec.CommandContext` with request input, but argv form (no shell), full 40-hex SHA regex (cannot start with `-`), timeout, auth check | no Critical/High | — |

tc-sec4 and tc-sec7 also run `format_check` (security-reviewer-format.bats) on
the report.

## Notes

- **Tier choices.** SKILL.md's rubric puts "authentication bypass, unrestricted
  data access" at Critical and "injection in authenticated context, significant
  data leakage" at High, so most defects accept either tier. tc-sec6 is pinned
  to Critical (remote code execution is named verbatim).
- **tc-sec5 is the most ambiguous.** The rubric lists "weak cryptographic
  choices" as Medium, but a predictable reset token is an account-takeover
  path (authentication bypass). The fixture expects Critical|High; a Medium
  rating means the report judged the primitive, not the consequence.
- **Clean negatives forbid only Critical/High.** The floor rule pushes any
  named mechanism to at least Medium, so a hardening note (e.g. rate limiting
  on tc-sec8) may legitimately land at Medium; the false-positive signal is a
  Critical/High finding on safe code.
- Fixtures are file fragments: imported helpers (`verifySession`, `SessionFrom`,
  `requireAuth`) are not present. A good report states that dependency rather
  than assuming either way.
- Fixture files carry no comments naming the defect.
