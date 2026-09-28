# Integration Test Steps — #20 Auth API: Register, Login & httpOnly Cookie Session

**Purpose**: Exercise the boundaries between the Next.js Route Handlers, the Next.js Middleware + `src/lib/auth.js`, and the PostgreSQL datastore (via Sequelize) — observing effects that cross a component boundary. Also verifies the startup DB-connection behaviour (authenticate, not sync).
**Scope**: Route Handler ↔ DB persistence, Middleware ↔ Route Handler user resolution, and startup ↔ DB integration.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | [PR #29](https://github.com/revanta-biswas/conduit-helix-test/pull/29) |
| Confirm the story is in the build | `git log --oneline \| grep -i "#29\|1.2\|auth"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | `http://localhost:3000`, API under `/api/` |
| Local services that must be up | PostgreSQL (via Sequelize), schema from existing Sequelize CLI migrations |
| Test data / accounts to seed | None up front; cases create their own users. DB access (psql or an admin UI) is needed to observe persistence and inspect logs. |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log functional failures against a system that never started.

---

### TC-INT-01 — Register persists a user row in PostgreSQL

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-4 / REQ-F-10 |
| **Type** | Integration |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT + Postgres running. Direct read access to the DB (psql). No user `int01@example.com`. |
| **Test data** | Body: `{"user":{"username":"int01","email":"int01@example.com","password":"Passw0rd!23"}}` |

**Steps**
1. Register: `curl -s -X POST http://localhost:3000/api/users -H "Content-Type: application/json" -d '{"user":{"username":"int01","email":"int01@example.com","password":"Passw0rd!23"}}'`
2. In the DB, query the users table: `SELECT username, email, password FROM "Users" WHERE email='int01@example.com';` (TO CONFIRM: exact table/column names — from the Sequelize migrations, not source code).
3. Inspect the persisted row.

**Expected result**
- Exactly one row exists for `int01@example.com`.
- The stored password value is a bcrypt/argon-style HASH, not the plaintext `Passw0rd!23`.

**Pass/Fail criteria**: PASS if the row is persisted with a hashed (not plaintext) password. No row, a duplicate row, or a plaintext-stored password is a FAIL.
**Cleanup**: `DELETE FROM "Users" WHERE email='int01@example.com';`

---

### TC-INT-02 — Middleware + auth.js resolve the cookie to the persisted user across a boundary

| Field | Value |
|-------|-------|
| **Traces to** | AC-2, AC-5 / REQ-F-16, REQ-F-18 |
| **Type** | Integration |
| **Priority** | P1 |
| **Preconditions** | Registered user `int02@example.com` exists; a protected endpoint returns the current user. |
| **Test data** | Login body for `int02@example.com` / `Passw0rd!23`. |

**Steps**
1. Register and log in capturing the cookie into `int02.txt`.
2. Call the protected/current-user endpoint replaying only the cookie: `curl -s -b int02.txt http://localhost:3000/api/user`
3. Compare the returned user identity against the DB row for `int02@example.com`.

**Expected result**
- The Middleware verifies the cookie, `auth.js` resolves it, and the Route Handler returns the user whose email/username match the DB row created at registration — proving the cookie → middleware → DB resolution chain works end to end.

**Pass/Fail criteria**: PASS if the resolved user matches the persisted row. A mismatch, a null user, or a 401 with a valid cookie is a FAIL.
**Cleanup**: Delete `int02` user; delete `int02.txt`.

---

### TC-INT-03 — Unauthenticated request to a public endpoint passes through (soft auth boundary)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-16 |
| **Type** | Integration |
| **Priority** | P2 |
| **Preconditions** | SUT running. A public endpoint that runs through the middleware exists (TO CONFIRM: e.g. `GET /api/articles`). |
| **Test data** | None. |

**Steps**
1. Call the public endpoint with no cookie: `curl -i http://localhost:3000/api/articles`
2. Observe that the middleware does not block it.

**Expected result**
- Status `200`; the middleware attaches no user (or a null user) but still lets the request reach the handler and return data — the soft-auth pass-through works.

**Pass/Fail criteria**: PASS if the public request succeeds despite no cookie. A block/401 is a FAIL (soft auth misconfigured).
**Cleanup**: None.

---

### TC-INT-04 — Startup connects with authenticate() and does NOT mutate the schema

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-F-10 |
| **Type** | Integration |
| **Priority** | P1 |
| **Preconditions** | Postgres running with the migration-managed schema applied. Ability to read the app's startup logs and to inspect the DB schema before/after. |
| **Test data** | None. |

**Steps**
1. Before starting the app, capture the current schema: `\d "Users"` (or dump the DDL of the relevant tables) and note columns/indexes.
2. Start the app and capture its startup log output.
3. After startup, re-capture the schema and diff it against Step 1.
4. Search the startup logs for any `sync`/`ALTER TABLE` activity vs. a plain authenticate/connection-OK message.

**Expected result**
- The startup log shows a successful DB connection (authenticate), with NO `sync`/`alter` schema activity.
- The schema after startup is byte-for-byte identical to before startup — no columns added/changed by the app at boot.

**Pass/Fail criteria**: PASS if startup connects without altering the schema. Any `sync({alter:true})`-style schema mutation at startup, or a schema diff, is a FAIL.
**Cleanup**: None.

---

### TC-INT-05 — Register failure does not leave a partial/orphaned row

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-5 / REQ-F-10 |
| **Type** | Integration |
| **Priority** | P2 |
| **Preconditions** | SUT + Postgres running; DB read access. |
| **Test data** | Invalid body (missing password): `{"user":{"username":"int05","email":"int05@example.com"}}` |

**Steps**
1. Send the invalid register request with `curl -i`.
2. Query the DB for `int05@example.com`.

**Expected result**
- The request is rejected (4xx, Conduit error shape).
- NO row exists for `int05@example.com` — the failed registration did not partially persist a user.

**Pass/Fail criteria**: PASS if no orphaned row is created on a rejected registration. Any persisted row is a FAIL.
**Cleanup**: `DELETE FROM "Users" WHERE email='int05@example.com';` if present.
