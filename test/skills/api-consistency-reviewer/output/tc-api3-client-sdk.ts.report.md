# API Consistency Review: `subject.ts` (WorkspaceClient Team methods)

**Scope:** `subject.ts`, the block between `BEGIN CHANGE UNDER REVIEW` and `END CHANGE UNDER REVIEW` (lines 68–84)
**Date:** 2026-11-19

> ⚠️ **No code fact-check report provided.** API documentation claims have not been independently verified against implementation. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

## Baseline Conventions

This comes from the code outside the change block in `subject.ts` (lines 1–66). It is the only source file in the repo. `./http` is imported but not present, so I couldn't check how `HttpClient` behaves.

- **Method naming:** a verb and a singular noun in camelCase, using four verbs: `get<Resource>`, `list<Resources>`, `create<Resource>` and `delete<Resource>`. The User (lines 36–50) and Project (lines 52–66) resources both use exactly these four verbs. Nothing uses `fetch`, `find`, `load` or `remove`.
- **Parameter naming:** the single-resource methods take `<resource>Id: string` (`userId`, `projectId`).
- **Routes:** plural collection paths (`/users`, `/projects`). Single resources are `/<plural>/${encodeURIComponent(id)}`.
- **List methods:** take `options: ListOptions = {}` (`limit?`, `cursor?`), pass it as `query`, and return `Page<T>` (`{ data, nextCursor: string | null }`). Pagination is cursor-based.
- **Create methods:** take `input: Omit<T, "id">` and return the created `T` by POSTing to the collection.
- **Delete methods:** return `Promise<void>`.
- **Errors:** all handling is left to `HttpClient`. No method catches errors or reshapes them.
- **Update methods:** none exist for any resource.
- **The `Team` type** (lines 27–31) is pre-existing. It sits outside the change block, so the diff doesn't introduce it.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `fetchTeam` | method | `getUser`, `getProject` | `subject.ts:36`, `subject.ts:52` | **Inconsistent.** Single-resource reads use `get`; `fetch` appears nowhere else |
| `listTeams` | method | `listUsers`, `listProjects` | `subject.ts:40`, `subject.ts:56` | Consistent |
| `createTeam` | method | `createUser`, `createProject` | `subject.ts:44`, `subject.ts:60` | Consistent |
| `deleteTeam` | method | `deleteUser`, `deleteProject` | `subject.ts:48`, `subject.ts:64` | Consistent |
| `teamId` | param | `userId`, `projectId` | `subject.ts:36,48,52,64` | Consistent with the `<resource>Id` pattern |
| `options` (listTeams) | param | `options` in `listUsers`, `listProjects` | `subject.ts:40`, `subject.ts:56` | Consistent (same type and `{}` default) |
| `input` (createTeam) | param | `input` in `createUser`, `createProject` | `subject.ts:44`, `subject.ts:60` | Consistent (`Omit<T, "id">` shape) |
| `GET/DELETE /teams/:id`, `GET/POST /teams` | route | `/users`, `/users/:id`, `/projects`, `/projects/:id` | `subject.ts:37–65` | Consistent: plural collection, encoded ID segment |

## Findings

#### `fetchTeam` breaks the `get<Resource>` naming convention

**Severity:** Inconsistent
**Location:** `subject.ts:69`
**Move:** #2 Check naming against the grain
**Confidence:** High

Precedent: `get<Resource>(<resource>Id)` used in `subject.ts:36` (`getUser`) and `subject.ts:52` (`getProject`)

Every other single-resource read on `WorkspaceClient` uses the `get` verb. The other three new Team methods (`listTeams`, `createTeam`, `deleteTeam`) also follow the sibling verbs exactly, which makes `fetchTeam` the only outlier in an otherwise uniform `get`/`list`/`create`/`delete` set.

This affects consumers. Someone who already uses `getUser` or `getProject` will naturally write `client.getTeam(id)`. That fails to compile, and they then have to find out that this one resource uses a different verb. It also suggests to readers that `fetch` means something different from `get` (for example, bypassing a cache or a forced refresh), but the implementation is identical to its siblings (`this.http.get(...)`, line 70).

Because the change hasn't shipped yet, renaming it costs nothing now. Once published, a rename would be a breaking change for this package's public entry point.

**Recommendation:** Rename `fetchTeam` to `getTeam` before release. Don't add a `fetchTeam` alias: no consumers depend on it yet, and an alias would make the inconsistency permanent.

## What Looks Good

- **`listTeams`** copies the established pagination contract exactly: `ListOptions` with an `= {}` default, passed as `query`, returning `Page<Team>` with cursor-based `nextCursor: string | null`. Consumers' existing pagination helpers will work without changes.
- **`createTeam`** uses the same `Omit<T, "id">` input shape and POST-to-collection route as `createUser` and `createProject`. Create and read are symmetric: every field accepted on create (`name`, `memberIds`) comes back on `Team`.
- **`deleteTeam`** returns `Promise<void>` and uses `DELETE /teams/:id`, matching its siblings.
- **Routes** use the plural `/teams` collection and always wrap the ID in `encodeURIComponent`, so the safe-encoding pattern is followed on both ID-taking methods.
- **`teamId`** matches the `<resource>Id` parameter naming.
- **Backward compatibility:** every change is an addition. No existing method, type or field is modified, so nothing in the diff can break existing consumers and no version bump is needed beyond a minor release.
- **Errors and idempotency:** error handling is left to `HttpClient` like every sibling, so errors will have the same shape. Create uses POST with no idempotency key, matching `createUser` and `createProject`. No inconsistency is introduced, though the codebase has no idempotency mechanism anywhere.
- **No update method:** leaving out `updateTeam` matches the existing resources, none of which have one.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| 1 | `fetchTeam` breaks the `get<Resource>` naming convention | Inconsistent | `subject.ts:69` | High |

## Overall Assessment

The change is highly consistent with the existing `WorkspaceClient` API. Three of the four new methods match their User and Project siblings exactly in naming, parameter shape, route structure, pagination envelope and return types. The author clearly followed the existing pattern. The one exception is `fetchTeam`, an isolated naming slip that can be fixed in place with a one-line rename to `getTeam`. It doesn't point to a wider gap in surveying conventions. The change is purely additive, so existing consumers can't break. The only cost is the friction new Team consumers would hit if `fetchTeam` ships, and that becomes hard to undo after release.
