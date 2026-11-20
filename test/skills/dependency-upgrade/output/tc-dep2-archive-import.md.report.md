## Dependency Upgrade Evaluation: tarnish 2.3.1 → 2.3.4

### Summary
**Recommendation:** **Upgrade now.** Don't wait for the quarterly sweep. Ship it with a small error-handling change in `import_bundle`.
**Breaking change impact:** Mechanical. No API breaks, but one intended behavior change: unsafe entries now raise `UnsafeEntryError`, which the importer should handle.
**Estimated effort:** About an hour, including the handler, a regression test and the rollback rehearsal.
**Risk:** Low for the upgrade itself. The risk of *not* upgrading is high.
**Audit state:** Unverified. No audit was run because this session has no shell or network. The vulnerability assessment below comes only from the release notes you supplied for TARN-2026-0117.

### Motivation
Version 2.3.4 fixes **TARN-2026-0117**, a path-traversal flaw in `extract_all()`. Archive entries with `..` components or absolute paths could be written outside the destination directory. The notes say versions 2.0.0 through 2.3.3 are affected, which includes our pinned 2.3.1.

**This project's usage matches the vulnerable pattern exactly:**

| Factor | This project |
|---|---|
| Vulnerable function used? | Yes. `archive.extract_all(dest)` in `sketchbook/bundles/importer.py` is the only extraction call. |
| Is the archive attacker-controlled? | Yes. It comes from `upload.file`, uploaded through `POST /bundles/import`. |
| Who can reach it? | Any signed-in account. |
| Where do bundles come from? | Other people's exports, shared by email or chat. That makes them untrusted third-party content. |
| Any validation before extraction? | None. |

So any account holder, or anyone who persuades a user to import a crafted `.skb` file, can write files anywhere the server process has write access. That includes other accounts' workspaces, application code and config files, and possibly cron or shell startup files. Depending on what the process can overwrite, this can lead to remote code execution.

Creating such an archive is trivial, since an entry named `../../x` is enough. Treat this as a vulnerability with a known exploitation technique, even though the notes don't mention exploits in the wild. That puts it in the "urgent" tier, not the "next sweep" tier.

### Breaking Changes That Affect This Project

| Change | Affected code | Migration |
|--------|--------------|-----------|
| `extract_all()` now raises `UnsafeEntryError` for entries with `..` or absolute paths (2.3.4). This is not an API break, but archives that used to "succeed" will now raise. | `sketchbook/bundles/importer.py` → `import_bundle` → `archive.extract_all(dest)`. The exception would surface from `POST /bundles/import` in `sketchbook/api/routes.py`. | Catch `tarnish.UnsafeEntryError` and return a 4xx response (e.g. 400 "Bundle contains unsafe paths") instead of letting it become a 500. Check the 2.3.4 docs for the exact import path of the exception, since the notes give only its name. |

### Breaking Changes That Don't Affect This Project
- **2.3.3**, faster listing for archives with more than 10,000 entries. The project never lists archives. This is a performance change only.
- **2.3.2**, `tarnish.open()` accepts `os.PathLike`. This is additive. We pass a file object (`upload.file`), which is unaffected.
- **2.3.2**, documentation fixes. No code impact.
- The notes say no release in this range contains a breaking change.

### Transitive Effects
- None identified from the release notes. They mention no new dependencies, peer constraints or Python version changes, and our `requires-python = ">=3.11"` is unaffected as far as the notes indicate.
- Unverified: whether 2.3.4 changes tarnish's own dependency requirements. Confirm this during the resolver/install step below.
- If the project has a lockfile (`uv.lock`, `poetry.lock`, `requirements*.txt`), it must be regenerated together with the `pyproject.toml` pin. I couldn't see whether one exists.

### Execution Evidence

| Command | Exit | As-of | Evidence |
|---------|------|-------|----------|
| `grep -rn "tarnish" --include='*.py' .` (confirm the two listed call sites are the only ones) | — | — | Unverified. Recommended pre-merge check. I relied on your statement that these are all the call sites. |
| `pip-audit` (or `uv pip audit` / equivalent) against the current lock | — | — | Unverified. Recommended pre-merge check. |
| Install / lock resolution with `tarnish==2.3.4` | — | — | Unverified. Recommended pre-merge check. |
| Test suite, including a new traversal regression test | — | — | Unverified. Recommended pre-merge check. |
| Rollback rehearsal verification | — | — | Unverified. Recommended pre-merge check. |

No command was run in this session. Nothing above is a result; every row is a check to perform.

### Risk Factors
- **Partial extraction on failure (check this).** The notes don't say whether 2.3.4 validates every entry before writing, or raises partway through. If it raises mid-archive, a rejected bundle may leave some files in the workspace. Check the 2.3.4 docs or source. If validation isn't done up front, extract to a temporary directory and move it into place only on success. Alternatively, clean up `dest` on error.
- **Residual traversal vectors that the fix may not cover.** The notes mention only `..` and absolute paths. They don't mention **symlink or hardlink entries**. For example, a link entry `foo -> /etc` followed by a regular entry `foo/passwd` is a classic bypass. They also don't mention Windows-style paths such as `..\` or drive letters. Until you've confirmed tarnish handles these, consider rejecting link entries before calling `extract_all()`, if the API allows inspecting entries.
- **Compromise may already have happened.** The route has been exposed for as long as 2.0.0 through 2.3.3 was deployed. Consider checking upload logs and the filesystem for unexpected writes outside workspace directories. Whether that's worth doing is a judgment call based on how widely the feature is used.
- **Unrelated, same function:** `import_bundle` is `async` but makes blocking `extract_all` calls, so large bundles stall the event loop. This doesn't affect the upgrade decision. It's mentioned only because you'll be editing this function anyway.
- **Detectability:** This is low-risk to verify. A single test that uploads an archive containing `../escape.txt` and asserts a 4xx response with no file outside `dest` covers the fix and guards against regression.

### Rollback Plan (precondition: complete before starting the Migration Plan)

**Exact rollback commands** (adjust to your installer; I couldn't see which one you use):
```
git checkout <pre-upgrade-commit> -- pyproject.toml <lockfile-if-any>
# uv:     uv sync --frozen
# pip:    pip install -e . && pip install "tarnish==2.3.1"
# poetry: poetry install --sync
```
No data or config migrations are involved, so there's nothing else to undo.

**Verification step** (run after rolling back; it must pass):
`python -c "import tarnish, importlib.metadata as m; print(m.version('tarnish'))"` should print `2.3.1`. Then run the existing bundle-import test(s) and confirm they pass.

**Rehearsal status:** [ ] Not rehearsed. I couldn't execute anything here. Rehearse on a scratch branch (e.g. `scratch/tarnish-rollback`) and capture the verification output before merging.

Note the trade-off: rolling back reintroduces TARN-2026-0117. If you ever need to roll back, disable `POST /bundles/import` at the same time, or put a manual entry-name check in front of extraction.

### Migration Plan
1. **Interim mitigation if the deploy can't happen today:** disable or feature-flag `POST /bundles/import`. The route is exploitable now.
2. Rehearse the rollback above on a scratch branch.
3. Change `pyproject.toml` from `"tarnish==2.3.1"` to `"tarnish==2.3.4"` and regenerate the lockfile if there is one.
4. In `import_bundle`, catch `tarnish.UnsafeEntryError` and raise a 400-class HTTP error. Also guard against partial extraction (temp dir plus move, or cleanup on error) unless the docs confirm validation happens before any write.
5. Optionally, reject symlink and hardlink entries before extraction until you've confirmed tarnish handles them safely.
6. Add regression tests that upload archives containing a `../` entry, an absolute-path entry and a symlink-escape entry. Each should return 4xx and write no file outside `dest`.
7. Run the full test suite, a dependency audit and the grep from the evidence table. Capture their output.
8. Run the **security-reviewer** skill on the resulting diff before merging, since this upgrade is CVE-motivated and touches the error-handling path.
9. Deploy promptly, then decide whether to investigate past imports for signs of exploitation.

### If Not Upgrading
Not upgrading isn't a reasonable option while the route stays exposed to all signed-in accounts and accepts third-party bundles. Deferral would only be acceptable if `/bundles/import` were disabled, or restricted to fully trusted bundle sources, until the sweep.
