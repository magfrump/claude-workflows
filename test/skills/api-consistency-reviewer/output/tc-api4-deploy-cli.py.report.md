> ⚠️ **No code fact-check report provided.** API documentation claims have not been independently verified against implementation. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

# API Consistency Review: `shipit rollback` subcommand

**Scope:** `subject.py`, the block between `BEGIN CHANGE UNDER REVIEW` and `END CHANGE UNDER REVIEW` (lines 34–42)
**Date:** 2026-11-19

## Baseline Conventions

These come from the existing `deploy`, `scale` and `status` subcommands (`subject.py:14-32`):

- **Subcommand names:** bare lowercase verbs or nouns (`deploy`, `scale`, `status`).
- **Long flags:** always kebab-case: `--dry-run`, `--wait-timeout`, `--output-format`. No existing flag uses underscores.
- **Positional arguments:** the primary resource goes first and is positional (`build_id` for deploy, `service` for scale).
- **`--env`:** required on every mutating command (deploy, scale). Optional only on the read-only `status`.
- **Shared mutating flags:** `--dry-run` (`store_true`, help text "Print the plan without applying it") and `--wait-timeout` (`int`, default `300`, help text "Seconds to wait for health checks") appear in identical form on every mutating command.
- **Dispatch:** `set_defaults(func=commands.<subcommand>)`. The handler name matches the subcommand name.
- **Build identifiers:** called "build id" and taken as the positional `build_id` (deploy).

`shipit/commands.py` is not in the repository, so I could not check the handler side of the contract.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `rollback` | subcommand | `deploy`, `scale`, `status` | `subject.py:14,21,29` | Consistent: a bare lowercase verb |
| `service` (positional) | param | `service` (scale), `build_id` (deploy) | `subject.py:22,15` | Consistent: same name and position as `scale` |
| `--env` (required) | flag | `--env` required on deploy/scale; optional on status | `subject.py:16,23,30` | Consistent: mutating commands require it |
| `--to-build` | flag | `build_id` (deploy positional), `--wait-timeout`, `--output-format` | `subject.py:15,18,31` | Consistent: kebab-case. It is the first optional flag that refers to a build, but "build" matches the existing domain noun |
| `--dry_run` | flag | `--dry-run` (deploy), `--dry-run` (scale) | `subject.py:17,25` | **Inconsistent:** snake_case, while every other flag uses kebab-case |
| `--wait-timeout` | flag | `--wait-timeout` (deploy, scale) | `subject.py:18,26` | Consistent: same type, default and help text |
| `commands.rollback` | handler | `commands.deploy`, `commands.scale`, `commands.status` | `subject.py:19,27,32` | Consistent: handler name matches subcommand |

## Findings

#### 1. `--dry_run` uses snake_case; every other flag uses kebab-case

**Severity:** Inconsistent
**Location:** `subject.py:39`
**Move:** #2 Check naming against the grain
**Confidence:** High

Precedent: kebab-case long flags (`--dry-run`, `--wait-timeout`, `--output-format`) used in `subject.py:17,18,25,26,31`

`deploy` and `scale` both spell the flag `--dry-run`. `rollback` spells it `--dry_run`.

argparse treats `-` and `_` as different characters in option strings, so running `shipit rollback api --env prod --dry-run` fails with `unrecognized arguments: --dry-run` (exit code 2). The prefix matching in argparse does not help, because `--dry-run` is not a prefix of `--dry_run`.

This fails safely: the rollback does not run. But scripts and muscle memory carried over from `deploy` and `scale` will break, and users have to remember one odd spelling for one subcommand. The resulting attribute is `args.dry_run` for both spellings, so the handler is unaffected and the only damage is to the CLI contract. Fixing it now is cheap. Once scripts depend on `--dry_run`, renaming it becomes a breaking change.

**Recommendation:** Change the flag to `"--dry-run"`. If any build has already shipped with `--dry_run`, keep it as a hidden alias (`add_argument("--dry-run", "--dry_run", ...)`) so existing callers keep working.

#### 2. Shared mutating flags are copied by hand into each subcommand

**Severity:** Informational
**Location:** `subject.py:17-18, 25-26, 37, 39-40`
**Move:** #1 Establish the baseline conventions
**Confidence:** Medium

`--env`, `--dry-run` and `--wait-timeout` are written out separately in each mutating subcommand. Finding 1 happened because a copy drifted. With a third copy, the risk of further drift grows: a different default, help text or type on one command.

**Recommendation:** You don't need this to merge. A follow-up could move the shared flags into a parent parser (`argparse.ArgumentParser(add_help=False)` passed via `parents=[...]`) or a helper such as `_add_mutation_flags(p)`, so new subcommands get the same flags automatically.

#### 3. Handler contract for `commands.rollback` could not be checked

**Severity:** Informational
**Location:** `subject.py:41`
**Move:** #3 Trace the consumer contract
**Confidence:** Low

`shipit.commands` is not in the repository, so I could not confirm that `commands.rollback` exists. I also could not confirm that it reads `args.to_build` and treats `None` as "previous build", as the help text says. If the handler instead expects a name like `args.build_id` to match `deploy`, it will raise `AttributeError` when it runs.

**Recommendation:** Check that `commands.rollback` reads `args.service`, `args.env`, `args.to_build`, `args.dry_run` and `args.wait_timeout`, and handles `to_build is None`.

## What Looks Good

- The `rollback` subcommand name and its `commands.rollback` handler follow the existing verb and dispatch pattern.
- The positional `service` matches `scale` exactly, so the "resource first, positional" convention holds.
- `--env` is required, which matches the other mutating commands.
- `--wait-timeout` is identical to the existing flag in type (`int`), default (`300`) and help text.
- `--to-build` is kebab-case and optional, with a sensible default (previous build) stated in the help text. "build" matches the existing domain noun. Adding the subcommand is backward-compatible: no existing command changes.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `--dry_run` uses snake_case; every other flag uses kebab-case | Inconsistent | `subject.py:39` | High |
| 2 | Shared mutating flags are copied by hand into each subcommand | Informational | `subject.py:17-18,25-26,37,39-40` | Medium |
| 3 | Handler contract for `commands.rollback` could not be checked | Informational | `subject.py:41` | Low |

## Overall Assessment

The new `rollback` subcommand mostly matches the conventions set by `deploy`, `scale` and `status`: naming, positional order, required `--env`, `--wait-timeout` and dispatch. There is one real inconsistency: `--dry_run` should be `--dry-run`. As written, users who carry the flag over from `deploy` or `scale` get an argparse error. It fails safely, but it's an annoying gap in the CLI contract, and it becomes a breaking change to fix once scripts depend on it. It's a one-character fix now. The drift that caused it points to factoring the shared mutating flags into one place. No existing consumers are affected, because the change only adds a subcommand.

---

I printed the report here only. Per your instructions, nothing was saved to `docs/reviews/`.
