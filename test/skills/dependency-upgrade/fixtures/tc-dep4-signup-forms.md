# Upgrade request: formwright 5.2.0 → 6.0.0

`formwright` handles all forms in our customer web app. A developer wants the
new `useFieldArray` hook in 6.0 for a repeating-address form planned next
quarter, and asks whether we should upgrade now so the work can start early.

## Manifest (package.json)

```json
{
  "name": "tenant-portal-web",
  "dependencies": {
    "react": "18.3.1",
    "react-dom": "18.3.1",
    "formwright": "^5.2.0",
    "datepane": "^3.1.0"
  }
}
```

Peer requirements of the installed packages, from `package-lock.json`:

```text
formwright@5.2.0
  peerDependencies:
    react: >=17 <19
datepane@3.1.0
  peerDependencies:
    react: ^18.0.0
  latest release: 3.1.0
```

## How the project uses formwright

These are all of the call sites.

`src/forms/SignupForm.jsx`

```jsx
import { useForm, Field } from "formwright";
import { DatePane } from "datepane";

export function SignupForm({ onSubmit }) {
  const form = useForm({ initialValues: { email: "", moveIn: null } });
  return (
    <form onSubmit={form.handleSubmit(onSubmit)}>
      <Field form={form} name="email" type="email" required />
      <Field form={form} name="moveIn" as={DatePane} />
      <button type="submit">Create account</button>
    </form>
  );
}
```

`src/forms/ContactForm.jsx`

```jsx
import { useForm, Field } from "formwright";

export function ContactForm({ onSubmit }) {
  const form = useForm({ initialValues: { message: "" } });
  return (
    <form onSubmit={form.handleSubmit(onSubmit)}>
      <Field form={form} name="message" as="textarea" />
      <button type="submit">Send</button>
    </form>
  );
}
```

## Release notes (complete, 5.2.0 → 6.0.0)

### 6.0.0 (major)

- Peer dependencies: `react` and `react-dom` `^19.0.0`. formwright 6 is built
  on React 19 form actions and does not run on earlier React versions.
- New: `useFieldArray()` for repeating groups of fields.
- Breaking: `useForm({ validateOnMount })` was removed. Validation on mount is
  now always off.
- `Field` and `useForm` are otherwise unchanged.

### 5.3.0

- `Field` forwards `aria-*` props to the rendered input.
