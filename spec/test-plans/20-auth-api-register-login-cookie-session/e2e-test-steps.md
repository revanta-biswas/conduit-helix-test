# E2E Test Steps — #20 Auth API: Register, Login & httpOnly Cookie Session

**Purpose**: Verify the complete auth journey end to end as a user (or API client) experiences it: register -> login -> cookie set -> a subsequent request authenticated by that cookie resolves the correct user. This is the AC-5 full-flow journey.
**Scope**: The whole register-to-authenticated-request sequence, exercised as one continuous session. Cases here are journeys, not per-endpoint checks (those live in api-test-steps.md).

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | [PR #29](https://github.com/revanta-biswas/conduit-helix-test/pull/29) |
| Confirm the story is in the build | `git log --oneline \| grep -i "#29\|1.2\|auth"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | `http://localhost:3000`, API under `/api/` |
| Local services that must be up | PostgreSQL (via Sequelize), schema from existing Sequelize CLI migrations |
| Test data / accounts to seed | None up front; the journey creates its own user. |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log functional failures against a system that never started.

---

### TC-E2E-01 — Full auth flow: register -> login -> cookie -> authenticated request resolves the user

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 (and AC-1, AC-2) / REQ-F-10, REQ-F-15, REQ-F-16, REQ-F-18 |
| **Type** | E2E |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT + Postgres running. No user `e2e01@example.com`. Use a single cookie jar (`e2e01.txt`) across the journey to simulate one client session. |
| **Test data** | username `e2e01`, email `e2e01@example.com`, password `Passw0rd!23`. Current-user endpoint `GET /api/user` (TO CONFIRM: exact path). |

**Steps**
1. **Register**: `curl -s -c e2e01.txt -X POST http://localhost:3000/api/users -H "Content-Type: application/json" -d '{"user":{"username":"e2e01","email":"e2e01@example.com","password":"Passw0rd!23"}}'` — confirm 2xx.
2. **Fresh session — log in**: start a clean cookie jar and log in: `curl -s -c e2e01.txt -X POST http://localhost:3000/api/users/login -H "Content-Type: application/json" -d '{"user":{"email":"e2e01@example.com","password":"Passw0rd!23"}}'` — confirm 200 and that `e2e01.txt` now holds the session cookie.
3. **Authenticated request**: call the current-user endpoint replaying only the cookie jar: `curl -i -b e2e01.txt http://localhost:3000/api/user`
4. Inspect the returned user identity.

**Expected result**
- Registration succeeds; login returns 200 and sets the httpOnly session cookie into the jar.
- The subsequent cookie-only request returns 200 with the `user` object whose `email` is `e2e01@example.com` and `username` is `e2e01` — the correct user is resolved from the cookie with no Authorization header.

**Pass/Fail criteria**: PASS if the whole chain succeeds and the final request resolves exactly `e2e01`. A break at any step, or a wrong/absent user at the end, is a FAIL.
**Cleanup**: Delete `e2e01` user; delete `e2e01.txt`.

---

### TC-E2E-02 — Negative journey: registered user cannot reach protected data after logout / without the cookie

| Field | Value |
|-------|-------|
| **Traces to** | AC-5, AC-2 / REQ-F-16, REQ-F-18 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | A registered, logged-in user `e2e02@example.com` with a captured cookie jar. A protected endpoint identified. |
| **Test data** | username `e2e02`, email `e2e02@example.com`, password `Passw0rd!23`. |

**Steps**
1. Register and log in `e2e02`, capturing the cookie into `e2e02.txt`; confirm an authenticated request succeeds.
2. **Simulate the session ending**: either call the logout endpoint if one exists (TO CONFIRM: is there a `POST /api/users/logout` that clears the cookie?), OR discard the cookie jar to represent a new/unauthenticated client.
3. Repeat the protected request WITHOUT the valid cookie: `curl -i http://localhost:3000/api/user`

**Expected result**
- After the session ends / without the cookie, the protected request returns `401`/`403` in `{"errors":{"body":[...]}}` shape and returns no user data.
- If a logout endpoint exists, its response also clears the cookie (`Set-Cookie` with an expired/empty value).

**Pass/Fail criteria**: PASS if protected data is unreachable once the cookie is gone. Any protected data returned without a valid cookie is a FAIL.
**Cleanup**: Delete `e2e02` user; delete `e2e02.txt`.

---

### TC-E2E-03 — Two users' sessions do not cross over

| Field | Value |
|-------|-------|
| **Traces to** | AC-5, AC-2 / REQ-F-16, REQ-F-18 |
| **Type** | E2E |
| **Priority** | P2 |
| **Preconditions** | SUT running. Two distinct users can be created. |
| **Test data** | User A: `alice@example.com`/`Passw0rd!23`; User B: `bob@example.com`/`Passw0rd!23`. |

**Steps**
1. Register and log in Alice, capturing her cookie into `alice.txt`.
2. Register and log in Bob, capturing his cookie into `bob.txt`.
3. Call the current-user endpoint with Alice's cookie: `curl -s -b alice.txt http://localhost:3000/api/user`
4. Call the current-user endpoint with Bob's cookie: `curl -s -b bob.txt http://localhost:3000/api/user`

**Expected result**
- Alice's cookie resolves to `alice@example.com`; Bob's cookie resolves to `bob@example.com`. Neither cookie resolves to the other user or a shared/default account.

**Pass/Fail criteria**: PASS if each cookie resolves to its own user. Any cross-resolution is a FAIL (session isolation broken).
**Cleanup**: Delete both users; delete `alice.txt` and `bob.txt`.
