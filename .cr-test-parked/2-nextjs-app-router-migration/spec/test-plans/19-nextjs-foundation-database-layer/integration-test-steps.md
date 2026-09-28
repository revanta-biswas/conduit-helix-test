# Integration Test Steps — #19 Next.js Foundation & Database Layer

**Purpose**: Verify the new Next.js 15 App Router application boots and that its database
layer (`src/lib/db/**`) integrates correctly with the **existing PostgreSQL database** via
Sequelize — models load, associations resolve, connection settings are read from `.env.local`,
and the connection singleton survives dev-mode hot-reload. All cases exercise the boundary
between the running Next.js process and the PostgreSQL datastore from the outside.

**Scope**: Boundary between (a) the Next.js dev server process, (b) the Sequelize ORM layer
in `src/lib/db/`, and (c) the existing PostgreSQL database. Black-box: derived from acceptance
criteria only — no application source was read.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | [#28](https://github.com/revanta-biswas/conduit-helix-test/pull/28) |
| Confirm the story is in the build | `git log --oneline \| grep -i "1.1\|foundation\|database layer"` (expect the PR #28 merge commit) |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. The relevant command is the project's `next dev` script; run it from the new Next.js app root under `src/`. |
| Local base URL / port | http://localhost:3000 (default `next dev` port) |
| Local services that must be up | Existing PostgreSQL database, reachable with the credentials placed in `.env.local` (see AC-4). The DB must already contain the app schema/tables (Articles, Users, Tags, Comments, and the join tables for Favorites / Followers / TagList). |
| Test data / accounts to seed | At least one row in each of the four tables plus at least one row in each association join table, so `include`-based queries return non-empty results. If the DB is empty, seed per the project's own seed/migration docs. TO CONFIRM: exact seed/migration command (defer to project README). |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

> **How these black-box cases observe the DB layer**: this story ships no HTTP endpoint and no UI,
> so the observable surfaces are (1) the `next dev` process console/logs, (2) the OS-visible
> PostgreSQL connection count (via `psql` against the same DB), and (3) the result of the smoke test
> the story itself defines in AC-5. Where a case needs to invoke a model query, use the project's
> **documented smoke-test / REPL entry point** (AC-5 requires such a smoke test to exist). Do not
> read or import source modules directly. TO CONFIRM: the exact command/script the story exposes to
> run the AC-5 smoke test (e.g. an npm script or a documented node REPL snippet).

---

### TC-INT-01 — Next.js dev server boots without errors and connects to PostgreSQL

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-F-01, REQ-F-03, REQ-F-04 |
| **Type** | Integration |
| **Priority** | P1 (critical path) |
| **Preconditions** | Merged branch built and runnable per project docs; `.env.local` present with valid credentials for the existing PostgreSQL DB; PostgreSQL running and reachable. |
| **Test data** | Valid `.env.local` DB settings (host, port, database, user, password) matching the running PostgreSQL instance. |

**Steps**
1. From the Next.js app root, start the dev server using the project's documented `next dev` command.
2. Watch the process console output until it reports the server is ready (e.g. a "ready" / "Local: http://localhost:3000" line).
3. In a browser or via `curl -i http://localhost:3000/`, confirm the server answers.
4. Inspect the full console output from startup for error/stack-trace lines related to Sequelize or database connection (e.g. `SequelizeConnectionError`, `ECONNREFUSED`, `password authentication failed`).

**Expected result**
- The dev server reaches a ready state and serves http://localhost:3000 (any valid HTTP response — 200/redirect/404 for an unimplemented route is acceptable; a process crash is not).
- No Sequelize connection errors or unhandled exceptions appear in the startup console output.

**Pass/Fail criteria**: PASS if the server starts, stays running, and the console shows a successful DB connection (or at minimum no DB connection errors). FAIL on any startup crash, unhandled exception, or Sequelize connection error.
**Cleanup**: Stop the dev server (Ctrl-C).

---

### TC-INT-02 — Smoke test: all 4 models load and associations are queryable (happy path)

| Field | Value |
|-------|-------|
| **Traces to** | AC-5, AC-2 / REQ-F-02, REQ-F-05 |
| **Type** | Integration |
| **Priority** | P1 (critical path) |
| **Preconditions** | TC-INT-01 passed (server boots, DB connects). DB seeded with at least one Article that has at least one associated Tag and an author User, so an `include` query returns a populated row. |
| **Test data** | Seeded Article with `tagList` (>=1 tag) and an author User; the AC-5 example query `Article.findAll({ include: [Tag, User] })`. |

**Steps**
1. With the dev server running (or via the project's documented smoke-test entry point), invoke the story's smoke test that loads the four models (Article, User, Tag, Comment).
2. Execute the association query `Article.findAll({ include: [Tag, User] })` (or the equivalent documented smoke-test invocation).
3. Observe the returned result and the process console.

**Expected result**
- All four models (Article, User, Tag, Comment) load without error.
- `Article.findAll({ include: [Tag, User] })` returns without throwing; the result is an array.
- Returned Article rows carry their associated Tag(s) and User (the eager-loaded associations are populated for the seeded row).
- No Sequelize eager-load / association errors (e.g. `EagerLoadingError`, "is not associated to") in the console.

**Pass/Fail criteria**: PASS if the query resolves without error and the seeded Article shows its included Tag and User. FAIL if any model fails to load, the query throws, or the associations are missing/unresolvable.
**Cleanup**: None (read-only query). Stop the smoke test / server if started for this case.

---

### TC-INT-03 — belongsToMany associations resolve (Favorites, Followers, TagList)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-02 |
| **Type** | Integration |
| **Priority** | P1 (critical path) |
| **Preconditions** | Server boots and DB connects (TC-INT-01). DB seeded so that: at least one User favorites at least one Article (Favorites); at least one User follows another User (Followers); at least one Article has >=2 Tags (TagList). |
| **Test data** | Seeded rows in each association join table. Association queries via the documented smoke-test entry point: an Article eager-loading its favoriting Users; a User eager-loading its followers/followed Users; an Article eager-loading its Tags. TO CONFIRM: the exact association alias names (e.g. `Favorites`, `Followers`, `tagList`) — confirm with the dev/BA against the ported `backend/models/`. |

**Steps**
1. Via the documented smoke-test entry point, run a query that eager-loads the Article↔User **Favorites** many-to-many association for the seeded favorited Article.
2. Run a query that eager-loads the User↔User **Followers** self-referential many-to-many association for the seeded follower/followed pair.
3. Run a query that eager-loads the Article↔Tag **TagList** many-to-many association for the seeded multi-tag Article.
4. Observe each result set.

**Expected result**
- Each of the three `belongsToMany` associations resolves without error.
- The favorited Article returns its favoriting User(s); the followed User returns its follower(s); the multi-tag Article returns all its Tags (>=2).
- No "is not associated to" or missing-through-table errors appear.

**Pass/Fail criteria**: PASS only if all three many-to-many associations (Favorites, Followers, TagList) resolve and return the expected non-empty related rows. FAIL if any one association is absent, misnamed, or errors.
**Cleanup**: None (read-only). Stop the smoke test / server if started for this case.

---

### TC-INT-04 — Connection settings read from `.env.local` (config equivalence)

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-F-04 |
| **Type** | Integration |
| **Priority** | P1 |
| **Preconditions** | Merged branch built. A valid, running PostgreSQL instance. Ability to edit `.env.local` and restart the dev server. |
| **Test data** | Two DB targets or two credential sets for the same DB: (A) the correct values; used to prove the app reads them from `.env.local`. |

**Steps**
1. Populate `.env.local` with the **correct** DB connection settings (host, port, database name, user, password) for the running PostgreSQL instance.
2. Start the dev server and run the AC-5 smoke test; confirm the DB connection succeeds (reuse TC-INT-01 / TC-INT-02 observation).
3. Stop the server. Change one setting in `.env.local` to a **distinct-but-still-valid** value that only works if `.env.local` is genuinely the source (e.g. point the database name at a second, equally valid DB, or change the port to a second running instance). TO CONFIRM: availability of a second valid DB/port for this equivalence check — otherwise this step is covered by the negative TC-INT-05.
4. Restart the server and observe which database the connection lands on (verify via `psql` `\conninfo` or by querying a marker row unique to that DB).

**Expected result**
- With correct settings in `.env.local`, the app connects successfully (step 2).
- After changing `.env.local` to the second valid target and restarting, the app connects to the **new** target — proving the connection settings are sourced from `.env.local` and not hardcoded.
- Behaviour is equivalent to the legacy `backend/config/config.js` connection (same host/port/db/user semantics).

**Pass/Fail criteria**: PASS if the app's actual DB connection follows the values in `.env.local` across a change. FAIL if the connection ignores `.env.local` (connects to a fixed/hardcoded target regardless).
**Cleanup**: Restore `.env.local` to the correct values; restart the server if further cases follow.

---

### TC-INT-05 — Negative: invalid DB credentials in `.env.local` fail cleanly

| Field | Value |
|-------|-------|
| **Traces to** | AC-4, AC-5 / REQ-F-04, REQ-F-03 |
| **Type** | Integration (negative) |
| **Priority** | P2 |
| **Preconditions** | Merged branch built. PostgreSQL running. Ability to edit `.env.local` and restart. |
| **Test data** | `.env.local` with a deliberately **wrong** password (or wrong host/port) for the DB. |

**Steps**
1. Edit `.env.local` and set the DB password to an invalid value (keep host/port/db/user pointing at the real, reachable instance so the failure is authentication, not "host down").
2. Restart the dev server and/or run the AC-5 smoke test.
3. Observe the console output and any smoke-test result.

**Expected result**
- The connection attempt fails with a clear, PostgreSQL-attributable error (e.g. `password authentication failed for user`, a `SequelizeConnectionError` / `SequelizeAccessDeniedError`).
- The failure is surfaced in logs; the process does not hang indefinitely or silently pretend to be connected.
- The error message does **not** print the plaintext password (see TC-SEC-02).

**Pass/Fail criteria**: PASS if an invalid credential produces a clear connection/authentication error and the model queries do not falsely report success. FAIL if the app hangs silently, reports a healthy connection, or crashes with an opaque/unhandled error that gives no indication the cause is credentials.
**Cleanup**: Restore the correct password in `.env.local`; restart the server.

---

### TC-INT-06 — Negative: missing/unreachable `.env.local` or DB is handled, not silently ignored

| Field | Value |
|-------|-------|
| **Traces to** | AC-4, AC-3 / REQ-F-04, REQ-F-03 |
| **Type** | Integration (negative/boundary) |
| **Priority** | P2 |
| **Preconditions** | Merged branch built. Ability to remove/rename `.env.local` and to stop PostgreSQL. |
| **Test data** | Two sub-scenarios: (A) `.env.local` renamed/removed; (B) `.env.local` correct but PostgreSQL stopped. |

**Steps**
1. **Sub-scenario A**: Rename `.env.local` (so no DB settings are present). Start the dev server and run the smoke test. Observe.
2. Restore `.env.local`.
3. **Sub-scenario B**: With correct `.env.local`, stop the PostgreSQL service. Start/restart the dev server and run the smoke test. Observe.

**Expected result**
- **A**: The app reports a clear "missing configuration / DB settings not found" style failure when it tries to use the DB — it does not connect to an unexpected default and does not silently proceed as if connected. TO CONFIRM: expected behaviour when DB env vars are absent (fail-fast on boot vs fail on first query) — confirm with dev.
- **B**: The connection attempt fails with a clear "cannot reach database" error (e.g. `ECONNREFUSED`). The process surfaces the error rather than hanging silently.

**Pass/Fail criteria**: PASS if both sub-scenarios produce a clear, attributable failure and never a false "connected" state. FAIL if the app silently ignores the missing config/DB or hangs with no diagnostic.
**Cleanup**: Restore `.env.local`; restart PostgreSQL; restart the server.

---

### TC-INT-07 — Sequelize singleton survives dev-mode hot-reload (no duplicate pools)

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-03 |
| **Type** | Integration (boundary — resource correctness) |
| **Priority** | P1 |
| **Preconditions** | Server boots and DB connects (TC-INT-01). Ability to trigger Next.js dev hot-reload (edit and save a source file, or navigate routes that trigger recompilation). Access to the PostgreSQL instance via `psql` (or a DB monitoring view) to count connections. |
| **Test data** | The connection-count query: `SELECT count(*) FROM pg_stat_activity WHERE datname = '<your_db_name>';` (use the database name from `.env.local`). Note the app's expected pool size. TO CONFIRM: configured Sequelize pool `max` size — needed to interpret the baseline count. |

**Steps**
1. Start `next dev` and let it fully boot with a DB connection established.
2. Run the connection-count query in `psql` and record the baseline number of connections owned by the app's DB user for this database.
3. Trigger a series of hot-reloads: edit and save a source file (or repeatedly hit routes that force recompilation) at least 5-10 times, allowing each reload to complete.
4. After the reloads settle, run the connection-count query again and record the number.
5. Repeat the reload cycle a few more times and re-measure to confirm the count is stable, not monotonically climbing.

**Expected result**
- The number of active DB connections for the app remains bounded and roughly constant across repeated hot-reloads (consistent with a single pool of the configured size).
- The connection count does **not** grow with each hot-reload (which would indicate a new Sequelize instance / new pool created per reload).

**Pass/Fail criteria**: PASS if the connection count stays stable (within the single configured pool size) across 10+ hot-reloads. FAIL if the connection count increases roughly in proportion to the number of reloads, indicating duplicate connection pools / leaked Sequelize instances.
**Cleanup**: Stop the dev server; confirm the app's connections drain from `pg_stat_activity`.

---

### TC-INT-08 — Existing `backend/` and `frontend/` remain present and untouched

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-01 |
| **Type** | Integration (boundary — coexistence) |
| **Priority** | P2 |
| **Preconditions** | Merged branch checked out. Access to the repository working tree. |
| **Test data** | The merge base of PR #28 (the commit immediately before the story merged) for a before/after comparison. |

**Steps**
1. In the checked-out merged branch, confirm the `backend/` and `frontend/` directories still exist at the repository root.
2. Confirm the new Next.js App Router application exists under `src/` (an `app/` directory / App Router layout is present, and `src/lib/db/` exists).
3. Run `git diff --stat <merge-base-of-PR-28>..HEAD -- backend/ frontend/` to confirm the story introduced no changes under `backend/` or `frontend/`.

**Expected result**
- `backend/` and `frontend/` are present and show **zero** changes attributable to this story's PR.
- The new Next.js App Router app is present under `src/` with `src/lib/db/` populated.

**Pass/Fail criteria**: PASS if the new app is added under `src/` and the diff touches no files under `backend/` or `frontend/`. FAIL if the story modified/removed anything in `backend/` or `frontend/`, or if the new App Router app is missing.
**Cleanup**: None (read-only inspection).

---

### TC-INT-09 — Boundary: association query on empty result set returns cleanly

| Field | Value |
|-------|-------|
| **Traces to** | AC-5, AC-2 / REQ-F-05 |
| **Type** | Integration (boundary) |
| **Priority** | P3 |
| **Preconditions** | Server boots and DB connects. Access to a table state where a queried Article has **no** associated Tags (either a seeded tag-less Article, or filter to one). |
| **Test data** | An Article row with an empty `tagList` and, if possible, no favorites. |

**Steps**
1. Via the documented smoke-test entry point, run `Article.findAll({ include: [Tag, User] })` filtered/scoped so it returns at least one Article that has no Tags.
2. Observe the returned row's Tag association.

**Expected result**
- The query resolves without error even when an included association is empty.
- The tag-less Article returns with an empty Tags collection (e.g. `[]`), not an error, and its User association still resolves.

**Pass/Fail criteria**: PASS if an Article with no Tags returns cleanly with an empty association collection. FAIL if an empty association causes an error or the query throws.
**Cleanup**: None (read-only).
