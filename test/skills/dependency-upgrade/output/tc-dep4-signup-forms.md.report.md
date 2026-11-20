## Dependency Upgrade Evaluation: formwright 5.2.0 → 6.0.0

### Summary
**Recommendation:** Defer. The upgrade is blocked right now. formwright 6 requires React 19, but `datepane`, which `SignupForm` depends on, has no release that supports React 19.
**Breaking change impact:** None for formwright's own API in this project. **Significant** once you count the React 18 → 19 upgrade that formwright 6 forces.
**Estimated effort:** Minutes for the formwright code changes (none are needed). Unknown, probably days, for the React 19 upgrade plus resolving `datepane`. That part needs its own evaluation.
**Risk:** High if done now. You would have to override or ignore `datepane`'s peer constraint, or replace `datepane`.
**Audit state:** Unverified. No audit was run, since this environment has no shell or network access.

### Motivation
A developer wants `useFieldArray()`, which is new in 6.0.0, for a repeating-address form planned next quarter. They want to upgrade early so that work can start sooner. There is no security, end-of-life, or transitive pressure. This is a feature-driven upgrade for work that has not started yet.

### Breaking Changes That Affect This Project

| Change | Affected code | Migration |
|--------|--------------|-----------|
| Peer deps `react` / `react-dom` now `^19.0.0`, and formwright 6 "does not run on earlier React versions" | `package.json` pins `react` and `react-dom` at `18.3.1`. This affects the whole app, not only the two form files. | Upgrade React to 19 first. That is a separate major upgrade and needs its own evaluation of every React usage in the app, which this request does not include. |
| *(Transitive consequence)* React 19 conflicts with `datepane@3.1.0` peer `react: ^18.0.0`. 3.1.0 is the latest release. | `src/forms/SignupForm.jsx` uses `<Field ... as={DatePane} />` | No compatible `datepane` exists. You would need to wait for a React-19-compatible `datepane`, replace it, or remove it from `SignupForm`. |

No formwright API change affects the project's own call sites. The blocker comes entirely from the React peer requirement.

### Breaking Changes That Don't Affect This Project
- **`useForm({ validateOnMount })` removed.** Both call sites pass only `initialValues` (`SignupForm.jsx`, `ContactForm.jsx`), so they don't use it. Validation-on-mount was not enabled before and is "always off" now, so behavior does not change.
- **`Field` and `useForm` are otherwise unchanged** in 6.0.0, according to the release notes. The project's usage (`useForm`, `form.handleSubmit`, `Field` with `form`, `name`, `type`, `required`, and `as`) needs no edits.
- **5.3.0: `Field` forwards `aria-*` props to the rendered input.** This is additive, and neither call site passes `aria-*` props to `Field`, so there is no impact. Note that 5.3.0 already falls inside the existing `^5.2.0` range. A fresh install without the lockfile could pick it up today.

### Transitive Effects
- **Forced React 18.3.1 → 19 upgrade** for `react` and `react-dom`. This affects the entire app, and its scope can't be judged from the information given.
- **Peer conflict with `datepane@3.1.0`** (`react: ^18.0.0`, latest release). With npm 7+ the install would fail with a peer-dependency resolution error unless you force past it with `--legacy-peer-deps` or `--force`. I have not run this, so it is a prediction. Forcing it would run `datepane` on an unsupported React version, so I don't recommend it.

### Execution Evidence

| Command | Exit | As-of | Evidence |
|---------|------|-------|----------|
| `npm install formwright@6.0.0` (peer-resolution check) | — | — | Unverified. Recommended pre-merge check. |
| `npm audit` | — | — | Unverified. Recommended pre-merge check. |
| `npm test` | — | — | Unverified. Recommended pre-merge check. |
| `npm view datepane versions peerDependencies` (confirm no React-19-compatible release) | — | — | Unverified. Recommended pre-merge check. The request says 3.1.0 is latest, but this should be re-checked when revisiting. |

Nothing was executed in this session. Every conclusion above comes from reading the supplied manifest, lockfile excerpt, call sites, and release notes.

### Risk Factors
- **Forcing past the peer conflict** would run `datepane` on React 19, which it doesn't declare support for. Any failure would hit the signup flow (`SignupForm`'s `moveIn` field), the entry point for new customers.
- **The React 19 upgrade is the real cost.** It touches the whole app, and its breaking changes would need evaluating against code not included here.
- **Upgrading early buys little.** The feature work is next quarter. Taking on React 19 risk now delivers no user value until then.
- **Detectability:** a peer conflict surfaces immediately at install. Runtime incompatibilities in `datepane` under React 19 might only show up when the date field is used. Tests that render `SignupForm` and interact with `moveIn` would be needed to catch them.

### Rollback Plan (precondition — complete before starting Migration Plan)

**Exact rollback commands:**
```
git checkout -- package.json package-lock.json
rm -rf node_modules
npm ci
```
(No data or config changes are involved in this upgrade.)

**Verification step** (run after rollback; it must pass to confirm the rollback worked):
`npm ls react react-dom formwright datepane` should show `react@18.3.1`, `react-dom@18.3.1`, `formwright@5.2.0`, and `datepane@3.1.0` with no peer errors. Then run the test suite covering `SignupForm` and `ContactForm`, including a submit through the `DatePane` field.

**Rehearsal status:** [ ] Not rehearsed. This environment has no shell. Rehearse on a scratch branch (e.g. `scratch/formwright-6-rollback`) before starting the migration, and capture the verification output as evidence.

### Migration Plan
Not recommended now. When the blockers clear, the steps would be:
1. Confirm a React-19-compatible `datepane` release exists, or decide on a replacement for the `moveIn` field in `SignupForm.jsx`.
2. Write a separate dependency-upgrade evaluation for React and react-dom 18.3.1 → 19 across the whole app, and finish that upgrade together with the `datepane` resolution.
3. Rehearse the rollback above on a scratch branch and record the evidence.
4. Bump `formwright` to `^6.0.0`. No call-site changes are needed in `SignupForm.jsx` or `ContactForm.jsx`.
5. Run `npm install` and confirm there are no peer warnings. Run tests, then manually check submitting both forms, including the date field.
6. Start the repeating-address form with `useFieldArray()`.

### If Not Upgrading
Revisit when **either** of these happens:
- `datepane` ships a release with a React 19 peer range, **or**
- the team decides to replace `datepane`, or the repeating-address work is scheduled firmly enough to justify the React 19 migration.

Watch the `datepane` releases now, so this blocker doesn't surprise you at the start of next quarter. If the address-form work must start early, run a timeboxed spike on a scratch branch. It should answer two questions: (a) how large the app-wide React 19 upgrade is, and (b) what the realistic `datepane` options are (wait, replace, or drop). The formwright side of the upgrade needs no code changes, so React 19 and `datepane` are the only real cost.
