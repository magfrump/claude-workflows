---
name: license-audit
description: >
  Check a project's dependency licenses against the company policy (permissive
  allowed; weak copyleft allowed for dynamically linked libraries; strong
  copyleft and unknown licenses blocked). Reads the lockfile, resolves each
  package's declared license, and lists violations with the package, version,
  license and the policy rule it breaks. Use when the user asks "are our
  licenses OK", "license audit", or before adding a dependency to a product
  that ships to customers.
---

# License Audit

1. Parse the lockfile (package-lock.json, poetry.lock, Cargo.lock, go.sum).
2. Resolve each package's SPDX license identifier.
3. Classify: permissive, weak copyleft, strong copyleft, unknown.
4. Report violations as a table: package | version | license | rule.
