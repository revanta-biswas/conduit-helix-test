# Security Test Steps — #19 Next.js Foundation & Database Layer

**Purpose**: Verify that the database credentials this story introduces are handled securely —
sourced from `.env.local` (not committed to the repo, not hardcoded) and never leaked into logs
or error output. This is the only security-relevant surface the story exposes (AC-4 introduces
credential handling); the story ships no auth, authz, HTTP endpoint, or user input surface.

**Scope**: Secret / credential handling for the Sequelize DB connection defined in
`src/lib/db/config.js` + `.env.local`. Maps to the AIRE Security Baseline rules on **credential
management** (secrets must not be committed to source control) and **secure logging / error
handling** (secrets must not appear in logs or error messages). Black-box: derived from
acceptance criteria only — no application source was read.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | [#28](https://github.com/revanta-biswas/conduit-helix-test/pull/28) |
| Confirm the story is in the build | `git log --oneline \| grep -i "1.1\|foundation\|database layer"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | http://localhost:3000 |
| Local services that must be up | Existing PostgreSQL DB reachable via the credentials in `.env.local`. |
| Test data / accounts to seed | None required beyond a valid `.env.local`. |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-SEC-01 — DB credentials and `.env.local` are not committed to source control

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-F-04 |
| **Type** | Security (credential management) |
| **Priority** | P1 |
| **Preconditions** | Merged branch checked out. Full git history available. |
| **Test data** | Common secret filenames and value patterns: `.env.local`, `password`, the PostgreSQL user/password actually used locally. |

**Steps**
1. Confirm `.env.local` is **not** tracked by git: run `git ls-files | grep -i "\.env"` — `.env.local` must not appear (a committed `.env.example` / `.env.sample` template with placeholder values is acceptable).
2. Confirm `.env.local` is git-ignored: run `git check-ignore .env.local` (expect it to report the path as ignored).
3. Search the whole tracked tree and history for hardcoded DB secrets: `git grep -i -e password -e "postgres://" -- 'src/**'` and `git log -p -S '<the actual DB password>' -- src/` (substitute the real local password). No real credential value may appear in any tracked file or historical commit.
4. Inspect `src/lib/db/config.js` behaviourally (via TC-INT-04 result, not by reading its logic for secrets): confirm connection values change with `.env.local`, proving they are not hardcoded.

**Expected result**
- `.env.local` is not tracked and is git-ignored.
- No real DB password/connection string is present in any tracked file or in git history.
- Any committed env template contains only placeholders, never real values.

**Pass/Fail criteria**: PASS only if `.env.local` is untracked + ignored AND no real credential value is found anywhere in tracked files or history. FAIL if `.env.local` is committed, if it is not ignored, or if any real secret appears in source/history.
**Cleanup**: None (read-only).

---

### TC-SEC-02 — DB credentials do not leak into logs or error output

| Field | Value |
|-------|-------|
| **Traces to** | AC-4, AC-5 / REQ-F-04, REQ-F-03 |
| **Type** | Security (secure logging / error handling) |
| **Priority** | P1 |
| **Preconditions** | Merged branch built and runnable. Ability to edit `.env.local` and restart. Ability to capture full server console output. |
| **Test data** | A recognisable, unique sentinel password value in `.env.local` (e.g. `SENTINEL_pw_9f3a2b`) so it can be searched for in output; and a wrong-password scenario to force an error path. |

**Steps**
1. Set the DB password in `.env.local` to the unique sentinel value `SENTINEL_pw_9f3a2b` (ensure the DB user actually has this password, or use it only for the failure path).
2. Start the dev server (happy path) and run the AC-5 smoke test; capture the full console output to a file.
3. Search the captured output for the sentinel: `grep -c "SENTINEL_pw_9f3a2b" <captured-output>` — expect **0** matches.
4. Force an **error** path: set `.env.local` to a wrong password (keep the sentinel as the wrong value) and restart; capture output.
5. Search the error-path output for the sentinel and for the full connection string — expect the password value to be absent (a redacted/masked form such as `****` is acceptable).

**Expected result**
- On both the happy path and the failure path, the DB password plaintext never appears in console output or logs.
- Connection error messages describe the failure (e.g. "authentication failed") without echoing the password or full DSN including the password.

**Pass/Fail criteria**: PASS if the sentinel password value appears **zero** times in all captured output across success and failure paths. FAIL if the password (or a full connection string containing it) is printed in any log line or error message.
**Cleanup**: Restore the correct password in `.env.local`; delete captured-output files containing the sentinel; restart the server.
