# Integration Test Steps — #24 Auth Pages & Session (Login, Register, Settings)

**Purpose**: Verify the boundaries the story wires together — the Client Component pages -> the auth
Route Handlers -> the session cookie -> PostgreSQL persistence. Each case exercises a boundary from
the outside and asserts an observable effect on the other side (network response, cookie, or
persisted data visible on reload). Black-box, manual.

**Scope**: Page -> API -> cookie boundary, and API -> PostgreSQL persistence boundary. Boundaries are
derived from the acceptance criteria and design intent, never from source. The Route Handler
internals themselves are covered by Story 1.2/1.3 API plans; here we verify the page-to-boundary wiring.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | PR #33 — https://github.com/revanta-biswas/conduit-helix-test/pull/33 |
| Confirm the story is in the build | `git log --oneline \| grep -i "1.6"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | http://localhost:3000 |
| Local services that must be up | PostgreSQL (via Sequelize); app server on :3000 |
| Test data / accounts to seed | A valid account for login/settings; register cases create fresh accounts |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-INT-01 — Register page calls the auth Route Handler and sets the session cookie

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-3 / REQ-F-24, REQ-F-28 |
| **Type** | Integration |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT running; PostgreSQL up; browser logged out; DevTools -> Network open |
| **Test data** | Username: `int_reg_01`; Email: `int_reg_01@example.com`; Password: `Passw0rd!123` |

**Steps**
1. Open DevTools -> Network (preserve log ON), navigate to http://localhost:3000/register.
2. Fill in and submit the registration form.
3. In the Network panel, locate the request the page issues to the Story 1.2 auth Route Handler
   (e.g. a POST to the users/register endpoint). TO CONFIRM: exact endpoint path with the dev.
4. Inspect the response status and the response headers (`Set-Cookie`), then check DevTools ->
   Application -> Cookies.

**Expected result**
- The page fires an HTTP request to the auth Route Handler and receives a 2xx response.
- A session cookie is set as a result of registration (visible in the Cookies panel).
- The account exists in PostgreSQL (verifiable by logging in later / an admin query).

**Pass/Fail criteria**: PASS if the page-to-Route-Handler call succeeds and a session cookie is
established at the boundary. No request fired, a non-2xx, or no cookie set is a FAIL.
**Cleanup**: Delete the `int_reg_01` account from PostgreSQL.

---

### TC-INT-02 — Login page calls the auth Route Handler and establishes the session

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-3 / REQ-F-24, REQ-F-28 |
| **Type** | Integration |
| **Priority** | P1 |
| **Preconditions** | SUT running; a valid account exists; browser logged out; DevTools -> Network open |
| **Test data** | Valid account credentials |

**Steps**
1. Open DevTools -> Network, navigate to http://localhost:3000/login.
2. Submit valid credentials.
3. Locate the login request to the auth Route Handler; inspect status and `Set-Cookie`.
4. Confirm a session cookie appears in DevTools -> Application -> Cookies.

**Expected result**
- The login request returns 2xx and establishes a session cookie; the app transitions to logged in.

**Pass/Fail criteria**: PASS if the page-to-Route-Handler login call succeeds and the session cookie
is set. A failure to call the handler or no cookie is a FAIL.
**Cleanup**: Log out.

---

### TC-INT-03 — Settings page issues PUT /api/user and persists to PostgreSQL

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-25 |
| **Type** | Integration |
| **Priority** | P1 |
| **Preconditions** | SUT running; logged in with a valid account; DevTools -> Network open |
| **Test data** | New bio: `INT persisted bio`; New image: `https://example.com/int.png`; New email: `int_settings_new@example.com` |

**Steps**
1. Log in, open DevTools -> Network, navigate to http://localhost:3000/settings.
2. Change bio, image, and email to the Test data values and submit.
3. In the Network panel, confirm the request method is PUT and the target path is `/api/user`.
4. Inspect the PUT response status and body.
5. Reload `/settings` (and/or query PostgreSQL) to confirm the updated values persisted.

**Expected result**
- The settings submit sends `PUT /api/user` and receives a 2xx response.
- The updated bio, image, and email are persisted (visible after reload / in the DB row).

**Pass/Fail criteria**: PASS if the request is a PUT to `/api/user`, returns 2xx, and the change is
persisted across a reload. A wrong method/path, a non-2xx, or a value not persisting is a FAIL.
**Cleanup**: Revert the account's bio/image/email to originals.

---

### TC-INT-04 — Authenticated session cookie is sent to protected API calls

| Field | Value |
|-------|-------|
| **Traces to** | AC-3, AC-4 / REQ-F-28 |
| **Type** | Integration |
| **Priority** | P1 |
| **Preconditions** | SUT running; logged in; DevTools -> Network open |
| **Test data** | Any valid account |

**Steps**
1. Log in and navigate to `/settings`.
2. In DevTools -> Network, select the request the page makes to load the current user (e.g. a GET to
   the current-user endpoint). TO CONFIRM: exact endpoint path with the dev.
3. Inspect the request's Cookie header (Request Headers section).
4. Submit a settings update and inspect the PUT `/api/user` request's Cookie header too.

**Expected result**
- The protected API requests carry the session cookie in the request; the server resolves auth from
  that cookie (2xx responses, correct current user returned). No auth token is passed via an
  `Authorization` header sourced from localStorage.

**Pass/Fail criteria**: PASS if protected calls are authorised via the session cookie. If requests
carry a bearer token pulled from localStorage, or are unauthorised, that is a FAIL.
**Cleanup**: Log out.

---

### TC-INT-05 — Boundary failure: settings update after session invalidation is refused

| Field | Value |
|-------|-------|
| **Traces to** | AC-3, AC-5 / REQ-F-25, REQ-F-28 |
| **Type** | Integration (negative) |
| **Priority** | P2 |
| **Preconditions** | SUT running; logged in with a valid account; DevTools open |
| **Test data** | New bio: `should not persist` |

**Steps**
1. Log in and open `/settings`; type a new bio but do NOT submit yet.
2. In another tab (same browser session), trigger logout — or delete the session cookie in DevTools
   -> Application -> Cookies.
3. Return to the settings tab and submit the update.
4. Inspect the PUT `/api/user` response and then reload to check persistence.

**Expected result**
- With no valid session, the PUT `/api/user` is refused (401/redirect to login); the bio change does
  NOT persist. TO CONFIRM: expected status code for an unauthenticated PUT with the dev.

**Pass/Fail criteria**: PASS if the update is refused and nothing persists once the session is gone.
Persisting the change without a valid session is a FAIL.
**Cleanup**: None (no persisted change expected).

---

### TC-INT-06 — Register boundary rejects a duplicate at the datastore

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-24 |
| **Type** | Integration (negative) |
| **Priority** | P2 |
| **Preconditions** | SUT running; an account already exists with the username/email below; DevTools -> Network open |
| **Test data** | Duplicate username/email of an existing account |

**Steps**
1. Navigate to `/register` logged out; enter the already-registered username/email; submit.
2. In DevTools -> Network, inspect the register request's response status and body.

**Expected result**
- The Route Handler returns an error response (e.g. 4xx with a validation body about the taken
  username/email); no new row is created in PostgreSQL and no session cookie is set.

**Pass/Fail criteria**: PASS if the duplicate is rejected at the boundary with an error response and
no new account/session. A 2xx or a duplicate row created is a FAIL.
**Cleanup**: None.
