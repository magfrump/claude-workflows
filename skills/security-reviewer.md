---
name: security-reviewer
description: >
  Review code changes for security vulnerabilities using structured cognitive moves that go beyond
  what static analysis tools catch. This is not a linter — it focuses on design-level security
  flaws, trust boundary violations, implicit assumptions about input safety, and patterns that
  create exploitable conditions. Produces a structured Markdown critique of code diffs. Use this
  skill when the user asks to "review for security", "check for vulnerabilities", "security audit
  this PR", "what could an attacker do with this", or "is this safe". Also trigger when code
  touches authentication, authorization, input handling, cryptography, file I/O, network calls,
  or serialization. NOTE: This skill can be invoked standalone or by a code-review orchestrator.
  If a code-fact-check report is provided, use it as your foundation for understanding what the
  code actually does and do not re-verify documented behavior.
when: Code touches auth, input handling, crypto, or trust boundaries
requires:
  - name: code-fact-check
    description: >
      A code fact-check report covering claims in comments, docstrings, and documentation
      against actual code behavior. Typically produced by the code-fact-check skill. Without
      this input, the security review proceeds on code analysis only — comments about security
      properties are not independently verified.
---

> On bad output, see guides/skill-recovery.md

# Security Code Review

You are reviewing code changes for security vulnerabilities. The point is not to find issues
a linter or SAST tool would catch — those are handled elsewhere. Your job is to apply
security-specific reasoning to find design-level flaws, implicit trust assumptions, and
patterns that create exploitable conditions even when each line of code looks correct in
isolation.

What follows is a set of cognitive moves for security analysis. Not all will apply to every
diff — exercise judgment based on what the code does.

## Scoping

By default, review files changed on the current branch relative to main:

```bash
git diff main...HEAD
```

If the user provides an explicit scope (file list, directory, or PR number), use that instead.
For each changed file, also read enough surrounding context to understand trust boundaries,
callers, and data flow — a diff alone is rarely sufficient for security analysis.

## Using the Code Fact-Check Report

If you have been provided a code-fact-check report alongside the diff, treat it as your
foundation for understanding what the code actually does.

Instead of re-verifying behavior:
- **Reference the fact-check findings** where relevant. If a comment claims "input is sanitized
  by middleware" and the fact-check says that's stale, that's a security-relevant finding you
  should build on.
- **Focus on security implications** of fact-check findings. A "mostly accurate" claim about
  thread safety might be fine for correctness but critical for security.
- **Prioritize your cognitive moves**, which are what this skill uniquely provides.

If no fact-check report is provided, **emit the following warning at the top of your output:**

> ⚠️ **No code fact-check report provided.** Claims about security properties in comments and
> documentation have not been independently verified. For full verification, run the
> `code-fact-check` skill first or use the code-review orchestrator.

Then proceed with security analysis based on reading the actual code.

## The Cognitive Moves

### 1. Trace the trust boundaries

Before analyzing individual code, map where trust transitions happen. Every system has
boundaries where data moves from less-trusted to more-trusted context: user input entering
the application, data crossing service boundaries, values read from external storage,
deserialized objects, URL parameters, HTTP headers, environment variables.

For each changed file, identify: what enters from outside? What leaves to somewhere else?
What assumptions does this code make about the trustworthiness of its inputs? The most
dangerous vulnerabilities happen when code on the trusted side of a boundary treats
untrusted data as safe — and the diff may be adding, moving, or removing a boundary
without making that explicit.

### 2. Find the implicit sanitization assumption

Most injection vulnerabilities don't come from missing sanitization — they come from
*assumed* sanitization that happens somewhere else. When code uses a value without
validation, trace backward: where is this value supposed to be cleaned? Is that actually
guaranteed to happen on every code path that reaches here?

The specific move: for each input that the changed code uses, ask "what would happen if
this value contained an attacker-controlled string?" Then trace whether anything between
the input source and this usage actually prevents that. Pay special attention to:
- Values that pass through multiple functions before use (sanitization assumed but not enforced)
- Values that are validated for format but not for content (e.g., regex checks that the string
  looks like an email but doesn't prevent SQL injection)
- Values from "internal" sources that were originally external (e.g., database fields that
  store user input)

### 3. Check the error path, not just the happy path

Security bugs hide in error handling. When an operation fails, what state is the system in?
Are partial results cleaned up? Are error messages leaking internal details? Does a failed
authentication check fall through to the next handler instead of returning early?

For every conditional or try/catch in the diff, ask: "What happens when this fails? Is the
failure state safe?" The most critical variant: when authentication or authorization checks
throw exceptions, does the catch block deny access or does it accidentally permit it?

### 4. Identify time-of-check to time-of-use gaps

When code checks a condition and then acts on it, ask whether anything can change between
the check and the use. This applies to:
- File existence checks followed by file operations
- Permission checks followed by privileged actions
- Balance checks followed by transfers
- Input validation followed by processing in a different function

The check and the use don't have to be on adjacent lines — they might be in different
functions, or the check might be cached. The question is: can an attacker (or concurrent
operation) change the state between when it was validated and when it was used?

### 5. Invert the access control model

Take whatever the code allows and ask: "what does this *prevent*?" Most access control
bugs come from confusion between allowlists and denylists, or from forgetting to check
at all. If the code checks that a user has role X, ask what happens for a user with no
role. If it validates that a resource belongs to the requesting user, ask what happens for
admin endpoints, system resources, or resources with null owners.

The specific move: for each authorization check, enumerate the cases it does NOT cover.
Then check whether those uncovered cases are safe by default (deny) or unsafe by default
(allow). Default-allow is almost always a bug.

### 6. Follow the secrets

When the diff touches credentials, tokens, API keys, session identifiers, or encryption
keys, trace their lifecycle: where are they created, where are they stored, where are they
transmitted, when are they invalidated? Check for:
- Secrets logged or included in error messages
- Secrets compared with timing-unsafe equality (`==` instead of constant-time comparison)
- Secrets stored in places with broader access than intended (localStorage, query parameters,
  world-readable files, environment variables inherited by child processes)
- Secrets that never expire or can't be revoked
- Secrets derived with insufficient entropy or predictable seeds

### 7. Test the serialization boundary

Whenever data is serialized (JSON, XML, protobuf, pickle, YAML) or deserialized, there's a
security surface. On the way out: is sensitive data being included that shouldn't be? On the
way in: can an attacker craft input that causes unexpected behavior during deserialization?

Check specifically for:
- Object properties that are serialized but shouldn't be (internal IDs, password hashes,
  tokens) — often caused by serializing an entire ORM model instead of a DTO
- Deserialization of untrusted data using formats that allow code execution (pickle, YAML
  with `!!python/object`, Java serialization)
- Type confusion when deserializing — does the code verify the shape of what it received, or
  does it cast and hope?

### 8. Ask "what if there are a million of these?"

Many security issues only appear at scale. A single request is fine; a million concurrent
requests create a denial of service. A single record is fine; a million records in a response
cause memory exhaustion. Rate limiting, pagination, resource cleanup, and connection pooling
are where these issues live.

For each operation in the diff, ask: can an unauthenticated (or low-privilege) user trigger
this repeatedly? If so, what's the cost per invocation? Is there any limit? This catches:
- Missing rate limiting on expensive operations
- Unbounded queries or response sizes
- Resource allocation without corresponding cleanup
- Amplification attacks (one request triggers many downstream operations)

### 9. Check the cryptographic choices

When the diff involves encryption, hashing, signing, or random number generation, verify
that the choices are current and appropriate. This is not about memorizing which algorithms
are good — it's about checking that:
- Random values used for security purposes come from cryptographic RNG (not `Math.random()`,
  not `rand()`, not time-based seeds)
- Hashing of passwords uses a purpose-built password hash (bcrypt, scrypt, argon2) not a
  fast hash (SHA-256, MD5)
- Encryption uses authenticated encryption (not ECB mode, not CBC without HMAC)
- Signatures are verified before the signed data is used
- Key sizes meet current recommendations

If you're not confident in your cryptographic assessment, say so and flag it for expert
review rather than guessing.

## How to Structure the Critique

Output your critique as a Markdown document.

### Trust Boundary Map
Briefly describe the trust boundaries in the changed code (move #1). What enters from
outside? What crosses between trust levels? This frames the rest of the review.

### Findings

For each finding, use this structure:

```
#### [Finding title]

**Severity:** [Critical / High / Medium / Low / Informational]
**Location:** `path/to/file.ext:42-58`
**Move:** [Which cognitive move surfaced this]
**Confidence:** [High / Medium / Low]

[2-5 sentences: what the vulnerability is, how it could be exploited, and what the
impact would be. Be specific about the attack scenario.]

**Recommendation:** [1-3 sentences: what to do about it.]
```

Severity guidelines:
- **Critical**: Remote code execution, authentication bypass, unrestricted data access
- **High**: Privilege escalation, significant data leakage, injection in authenticated context
- **Medium**: Information disclosure, missing rate limiting, weak cryptographic choices
- **Low**: Minor information leak, missing security headers, overly permissive CORS
- **Informational**: Defense-in-depth suggestions, hardening opportunities, non-exploitable patterns

Order findings by severity (critical first), then by confidence.

### What Looks Good
Note security practices in the diff that are correctly implemented. This prevents the
review from being purely negative and confirms which parts don't need rework.

### Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | ...     | Critical | `f:42`   | High       |

### Overall Assessment
One paragraph: what's the security posture of this change? Are the issues fixable in place
or do they indicate an architectural problem? What's the single most important thing to
address?

## Output Location

When run standalone, save your critique as `docs/reviews/security-review-{date}.md` (e.g., `security-review-2025-01-15.md`) in the project root with a `Commit: <hash>` metadata line at the top; create `docs/reviews/` if it doesn't exist.

When run via an orchestrator, the orchestrator specifies the output path — follow its
instructions.

## Tone

Direct and precise. Security review is not about making the developer feel bad — it's about
finding problems before an attacker does. State what's wrong, why it matters, and how to fix
it. Don't hedge on real issues, but calibrate confidence honestly. If you're not sure whether
something is exploitable, say so and explain what would need to be true for the attack to work.

## Important

- Read the actual implementation for every security-relevant code path. Do not rely on
  function names, type signatures, or comments as evidence of safety — read the code.
- Always read enough context beyond the diff to understand trust boundaries and data flow.
  A diff that adds input validation is only useful if you know what happens downstream.
- Do not report issues that static analysis tools reliably catch (unused variables, simple
  type mismatches). Focus on design-level and logic-level security.
- Do not suggest security theater (adding checks that cannot fail, over-validating trusted
  internal data). Every recommendation should address a realistic threat.
- When a finding depends on context you can't see (e.g., "this is safe IF the caller always
  validates"), say so explicitly rather than assuming either way.
