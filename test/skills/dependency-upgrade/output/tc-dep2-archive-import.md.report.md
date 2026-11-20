## Dependency Upgrade Evaluation: tarnish 2.3.1 → 2.3.4

### Summary
**Recommendation:** Upgrade now
**Breaking change impact:** Mechanical
**Estimated effort:** hours
**Risk:** Low
**Audit state:** Unverified

This should not wait for the quarterly sweep. The 2.3.4 fix (TARN-2026-0117) is a path-traversal bug in `extract_all()`. Our only call site uses exactly that function on archives uploaded by any signed-in account. The upgrade itself is low risk. The vulnerability it closes is high risk and reachable today.

"Mechanical" refers to one small adaptation: 2.3.4 now raises `UnsafeEntryError` on malicious archives, and the route should turn that into a 4xx instead of a 500. No API changes.

The audit state is unverified because no command was run, and I could not check the advisory database or the advisory text. Everything here relies on the release notes in the request.

### Motivation
This is a security fix. Per the 2.3.4 notes, `extract_all()` in 2.0.0–2.3.3 does not reject entries containing `..` components or absolute paths, so a crafted archive can write files outside the destination directory.

The project's exposure is direct:

| Factor | This project |
|---|---|
| Vulnerable function used? | Yes. `archive.extract_all(dest)` in `sketchbook/bundles/importer.py` is the project's only use of tarnish besides `open()`. |
| Input attacker-controlled? | Yes. `upload.file` comes straight from `POST /bundles/import`. |
| Who can reach it? | Any signed-in account. Bundles are also shared by email or chat, so a victim can be tricked into importing a malicious one, not just an attacker uploading their own. |
| What can be overwritten? | Anything writable by the server process: other accounts' workspaces (adjacent to `workspace_dir(account_id)`), config files, and potentially application code or startup files. That can escalate to code execution. |

This is a remotely reachable arbitrary-file-write for any authenticated user, plus a social-engineering vector against users who import shared bundles. Urgency: **upgrade now**.

The release notes don't say whether exploits are public. Classic "zip slip" bugs are trivial to exploit, so assume they are.

### Breaking Changes That Affect This Project

| Change | Affected code | Migration |
|--------|--------------|-----------|
| `extract_all()` now raises `UnsafeEntryError` for entries with `..` or absolute paths. This is a behavioral change, not an API break. | `sketchbook/bundles/importer.py` → `import_bundle()`; reaches `sketchbook/api/routes.py` → `import_route()` | Catch `tarnish.UnsafeEntryError` (confirm the exact import path in 2.3.4's docs) and return a 400/422 such as "bundle contains unsafe paths". Without this the attack is still blocked, but surfaces as a 500. Log the account id and filename when it fires. |

The release notes state that no release in this range contains a breaking change, and none of the listed changes alter the `open()` / `extract_all()` signatures we use.

### Breaking Changes That Don't Affect This Project
- **2.3.3**: faster listing for archives with more than 10,000 entries. This is a performance change only, and we don't call a listing API.
- **2.3.2**: `tarnish.open()` accepts `os.PathLike`. This is additive. We pass a file object (`upload.file`), so nothing changes.
- **2.3.2**: documentation fixes. No code impact.

### Transitive Effects
- None identified from the release notes. No new runtime requirement is mentioned, and `requires-python = ">=3.11"` is unaffected as far as the notes say.
- I can't see tarnish's own dependency metadata, so check that the resolver doesn't pull anything new (see Execution Evidence).

### Execution Evidence

Nothing was executed. There was no shell, repository, or network access for this evaluation.

| Command | Exit | As-of | Evidence |
|---------|------|-------|----------|
| `pip-audit` (or `uv pip audit` / equivalent) against the current lockfile | — | — | Unverified — recommended pre-merge check. It should flag TARN-2026-0117 on 2.3.1 if the advisory is in the database. |
| `pip-audit` after the bump to 2.3.4 | — | — | Unverified — recommended pre-merge check |
| Resolver install/sync after editing the pin (e.g. `uv sync` / `pip install -e .`) | — | — | Unverified — recommended pre-merge check. Confirm the only change in the lockfile diff is tarnish. |
| `grep -rn "tarnish" --include='*.py' .` to confirm the two call sites are the only usage | — | — | Unverified — recommended pre-merge check. The request states these are all of them, and I've relied on that. |
| Test suite, plus the new traversal tests below | — | — | Unverified — recommended pre-merge check |

### Risk Factors
- **The upgrade itself is low risk.** These are three patch releases with no API changes, and we use two functions.
- **The fix scope may be narrower than the threat.** The notes only mention `..` components and absolute paths. They don't say whether symlink or hardlink entries are handled, such as a link pointing outside `dest` followed by a regular file written through it. That is a common second traversal vector in archive libraries.
  - Add a test bundle with a symlink escaping `dest` and observe what 2.3.4 does.
  - If 2.3.4 doesn't block it, add our own pre-extraction check (reject link entries, or resolve each target path and confirm it stays under `dest`) or file it upstream.
- **Partial extraction is unknown.** The notes don't say whether `UnsafeEntryError` is raised before any file is written or partway through. If partway, a rejected bundle may leave a half-populated workspace. Extract into a temporary directory and move it into place on success, or clean up on error.
- **Prior exploitation can't be ruled out.** The bug has been reachable since the project adopted tarnish 2.x. After deploying, consider:
  - reviewing import logs for unusual bundles;
  - checking the server for unexpected files outside workspace directories, especially in code, config, and other accounts' workspaces.
- **Out of scope but noticed:** `import_bundle` is `async` but calls blocking `extract_all()` directly, which stalls the event loop on large bundles. Not related to this upgrade.
- **Required follow-up:** because the upgrade is CVE-motivated, run the **security-reviewer** skill on the resulting diff (pin bump plus the exception handling) before merging.

### Rollback Plan (precondition — complete before starting Migration Plan)

Rolling back reintroduces TARN-2026-0117. Use rollback only if 2.3.4 breaks bundle imports, and pair it with the interim mitigation under "If Not Upgrading" (disable the route). The package manager and lockfile aren't shown, so adjust these commands to your tool.

**Exact rollback commands:**
```
git checkout <pre-upgrade-commit> -- pyproject.toml <lockfile, e.g. uv.lock / requirements.lock>
uv sync --frozen          # or: pip install -r <lockfile> && pip install -e .
python -c "import importlib.metadata as m; print(m.version('tarnish'))"   # expect 2.3.1
```
No data or config changes are part of this upgrade, so nothing else needs unwinding.

**Verification step** (run after rollback; must pass to confirm rollback worked):
Run the bundle-import tests (e.g. `pytest tests/ -k import_bundle`) with a known-good `.skb` fixture. They should pass, and the version check should print `2.3.1`. That would fail if the lockfile or environment didn't fully revert.

**Rehearsal status:** [ ] Not rehearsed. I could not execute anything. Rehearse on a scratch branch (e.g. `scratch/tarnish-rollback`) and record the date and the captured verification output before starting the migration. This is a small rehearsal, roughly 10 minutes, and shouldn't delay the fix.

### Migration Plan
1. Change `"tarnish==2.3.1"` to `"tarnish==2.3.4"` in `pyproject.toml` and regenerate the lockfile. Confirm tarnish is the only package that changed.
2. In `import_bundle` / `import_route`, catch `UnsafeEntryError` and return a 4xx with a clear message. Log the account id and upload name.
3. Ideally, extract into a temporary directory and move it into `workspace_dir(account_id)` only on success, so rejected bundles leave no partial files.
4. Add regression tests with crafted fixtures:
   - an entry named `../escape.txt`;
   - an absolute-path entry such as `/tmp/escape.txt`;
   - a symlink entry pointing outside `dest`, plus a file written through it.

   Assert the request is rejected with 4xx and that nothing exists outside `dest`. The symlink case tells you whether you need your own guard (see Risk Factors).
5. Run the full test suite and a manual import of a real exported bundle.
6. Run `pip-audit` (or equivalent) before and after the change, and keep the output as evidence.
7. Run the security-reviewer skill on the diff, then merge and deploy promptly rather than batching with other work.
8. After deploying, do the exposure check described under Risk Factors.

### If Not Upgrading
Deferring to the quarterly sweep leaves an authenticated arbitrary-file-write open for up to three months, and no in-code mitigation currently exists. If the deploy can't happen within a day or two, disable `POST /bundles/import` (feature flag or route removal) until it can.
