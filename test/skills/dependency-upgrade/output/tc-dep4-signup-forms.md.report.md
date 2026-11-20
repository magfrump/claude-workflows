## Dependency Upgrade Evaluation: formwright 5.2.0 → 6.0.0

### Summary
**Recommendation:** Defer
**Breaking change impact:** Significant
**Estimated effort:** days (React 18 → 19 upgrade plus replacing or upgrading `datepane`); the formwright code changes alone take minutes
**Risk:** High
**Audit state:** Unverified

### Motivation
The upgrade is for a feature. A developer wants `useFieldArray()`, new in 6.0.0, for a repeating-address form planned for next quarter. They want to upgrade now so that work can start early. No security advisory, CVE, or end-of-life notice was mentioned, so urgency is low.

### Breaking Changes That Affect This Project

| Change | Affected code | Migration |
|--------|--------------|-----------|
| formwright 6.0.0 requires `react` and `react-dom` `^19.0.0` and "does not run on earlier React versions" | `package.json` (`react` and `react-dom` pinned to `18.3.1`); every formwright call site (`src/forms/SignupForm.jsx`, `src/forms/ContactForm.jsx`) | Upgrade React and React DOM to 19. This is a separate major upgrade and needs its own evaluation. |
| The forced React 19 upgrade conflicts with `datepane@3.1.0`, which declares peer `react: ^18.0.0`. 3.1.0 is datepane's **latest release**, so no datepane version supports React 19. | `package.json` (`datepane ^3.1.0`); `src/forms/SignupForm.jsx` (`import { DatePane } from "datepane"`, `<Field form={form} name="moveIn" as={DatePane} />`) | No upgrade path exists today. Options: (a) wait for a React 19-compatible datepane release, (b) replace datepane with a React 19-compatible date picker, or (c) force-install against an unmet peer range. Option (c) is not recommended because the move-in date field could break at runtime. |

The blocker is in the dependency graph, not the formwright API. formwright 6 needs React 19, the app's only other UI dependency cannot run on React 19, and that dependency has no newer release to move to.

### Breaking Changes That Don't Affect This Project
- **`useForm({ validateOnMount })` removed (6.0.0).** Neither call site passes `validateOnMount`. Both call `useForm({ initialValues: ... })` only, so no change is needed. Validation on mount was already off by default for this project's usage.
- **`Field` and `useForm` otherwise unchanged (6.0.0).** The project uses only `useForm`, `form.handleSubmit`, and `Field` with `form`, `name`, `type`, `required`, and `as` (string `"textarea"` and component `DatePane`). None of these are listed as changed.
- **`Field` forwards `aria-*` props (5.3.0).** This is additive. Neither call site passes `aria-*` props today, so nothing changes.

### Transitive Effects
- **React 18.3.1 → 19 forced.** `react` and `react-dom` must both move to `^19.0.0`. React 19's own breaking changes are not in the supplied release notes and I could not look them up. They need a separate evaluation covering the whole app, not just the two forms.
- **Peer conflict with `datepane@3.1.0`.** Its `react: ^18.0.0` peer range cannot be met alongside formwright 6, and no newer datepane release exists. Depending on the package manager and its configuration, installing will either fail with a peer-resolution error or succeed with an unmet-peer warning. I have not run the install to check which.
- **Minimum runtime/platform requirements:** none stated beyond React 19.

### Execution Evidence

| Command | Exit | As-of | Evidence |
|---------|------|-------|----------|
| `npm ls react react-dom formwright datepane` (confirm installed versions match the lockfile excerpt) | — | — | Unverified — recommended pre-merge check |
| `npm view datepane versions peerDependencies` (confirm 3.1.0 is still latest and still React-18-only) | — | — | Unverified — recommended pre-merge check |
| `npm audit` | — | — | Unverified — recommended pre-merge check |
| `npm install formwright@6.0.0 react@19 react-dom@19` on a scratch branch (observe peer-conflict behavior) | — | — | Unverified — recommended pre-merge check |
| `npm test` | — | — | Unverified — recommended pre-merge check |

No commands were run because this session had no shell, repository, or network access. Every finding above comes from the manifest, lockfile excerpt, call sites, and release notes supplied in the request. Two of those inputs are time-varying and should be re-checked before acting: the claim that datepane 3.1.0 is its latest release, and the audit state.

### Risk Factors
- **Runtime breakage of the move-in date field.** Forcing past datepane's peer range puts a component built for React 18 under React 19. This may fail at runtime rather than at install or compile time, and only in `SignupForm`, the account-creation path.
- **App-wide React major upgrade.** A feature that one future form needs would pull in a React major upgrade affecting the whole customer web app. The blast radius is much larger than formwright's own changes suggest.
- **Detectability.** Test coverage of `SignupForm` and `ContactForm` is unknown. A component test that renders `SignupForm` and submits a `moveIn` date would be the key regression check.
- **Low risk in formwright itself.** Its API changes don't touch this project's usage.

### Rollback Plan (precondition — complete before starting Migration Plan)

**Exact rollback commands:**
```
git checkout -- package.json package-lock.json
rm -rf node_modules
npm ci
# if datepane was replaced with another library, also revert the component change:
git checkout -- src/forms/SignupForm.jsx
```

**Verification step** (run after rollback; must pass to confirm rollback worked):
`npm ls react react-dom formwright datepane` must report `react@18.3.1`, `react-dom@18.3.1`, `formwright@5.x`, and `datepane@3.1.0`. After that, run a test that renders `SignupForm`, sets `moveIn` through the `DatePane` field, and submits. That test fails if React 19 or formwright 6 is left in `node_modules`.

**Rehearsal status:** [ ] Not rehearsed. This must be done on a scratch branch, with captured verification output, before any migration starts.

### Migration Plan
Not recommended now. Use this plan when the trigger below is met.
1. Resolve the datepane blocker first. Either upgrade to a datepane release whose peer range includes React 19, or replace `DatePane` in `src/forms/SignupForm.jsx` with a React 19-compatible date picker that works with `Field`'s `as` prop.
2. Evaluate and perform the React 18.3.1 → 19 upgrade (`react`, `react-dom`) as its own change, using its own run of this skill and its own rollback rehearsal.
3. Rehearse the rollback above on a scratch branch and capture the verification output.
4. Bump `formwright` to `^6.0.0` in `package.json` and reinstall.
5. Confirm `validateOnMount` is still unused anywhere. Today it appears in neither call site, so no code changes are expected in `SignupForm.jsx` or `ContactForm.jsx`.
6. Run tests and manually exercise signup (email plus move-in date) and contact submission.
7. Build the repeating-address form with `useFieldArray()`.

Keep steps 1–2 and step 4 in separate PRs so that a regression can be traced to React or datepane rather than formwright.

### If Not Upgrading
Revisit when **either** of these happens:
- datepane publishes a release supporting React 19, or
- the team decides to replace datepane anyway.

Either way, schedule the React 19 + datepane work at the start of next quarter, ahead of the repeating-address form, rather than now.

Staying on 5.x costs little in the meantime. The current `^5.2.0` range already permits 5.3.0, which adds `aria-*` forwarding with no breaking changes and could be taken now if useful. Until the upgrade happens, the address form can be prototyped with a hand-rolled repeating group on `useForm`, or its design can be settled with the `useFieldArray` API shape in mind.
