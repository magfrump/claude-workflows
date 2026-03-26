# Scope Exception: Cross-Reference Integrity Test

## Known pre-existing broken reference

`guides/validation-gates.md` line 99 references `skills/self-evaluation.md` but the
actual file is `skills/self-eval.md`. This is exactly the kind of breakage the new
test is designed to catch.

Fixing this reference requires modifying `guides/validation-gates.md`, which is
outside the allowed file scope for this task. The bare-path-references test will
fail until this is fixed in a separate change.
