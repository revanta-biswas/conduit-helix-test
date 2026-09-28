# API Test Steps — #20 Auth API: Register, Login & httpOnly Cookie Session

**Purpose**: Exercise the register and login Route Handlers as black-box HTTP endpoints — happy paths, error paths, auth absent/present, bad payloads, and Conduit-spec response-shape matching.
**Scope**: `POST /api/users` (register), `POST /api/users/login` (login), and cookie-authenticated retrieval of the current user (e.g. `GET /api/user`). Response-shape matching to the Conduit spec lives here (Contract plan is N/A for a monolith).

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | [PR #29](https://github.com/revanta-biswas/conduit-helix-test/pull/29) |
| Confirm the story is in the build | `git log --oneline \| grep -i "#29\|1.2\|auth"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | `http://localhost:3000`, API under `/api/` |
| Local services that must be up | PostgreSQL (via Sequelize), with schema applied by the existing Sequelize CLI migrations |
| Test data / accounts to seed | None required up front; register cases create their own users. A pre-seeded user is used for duplicate/login cases (see each case). |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log functional failures against a system that never started.

**Tooling note**: cases use `curl` from a terminal so cookie and header behaviour is visible. Use `-i` (or `-D -`) to print response headers, and `-c cookies.txt` / `-b cookies.txt` to persist and replay the session cookie. TO CONFIRM: the exact cookie name the app sets (assumed `token` below) — with the BA/dev.

---

### TC-API-01 — Register a new user succeeds and sets an httpOnly cookie

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-10 |
| **Type** | API |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT running per the block above. No existing user with email `apitest01@example.com`. |
| **Test data** | Body: `{"user":{"username":"apitest01","email":"apitest01@example.com","password":"Passw0rd!23"}}` |

**Steps**
1. Run: `curl -i -c cookies01.txt -X POST http://localhost:3000/api/users -H "Content-Type: application/json" -d '{"user":{"username":"apitest01","email":"apitest01@example.com","password":"Passw0rd!23"}}'`
2. Inspect the HTTP status line and the response headers.
3. Inspect the JSON body.
4. Open `cookies01.txt` and inspect the stored cookie attributes.

**Expected result**
- Status `200` (or `201` — TO CONFIRM: which the app returns; Conduit reference uses `200`/`201`).
- A `Set-Cookie` header is present carrying the JWT session cookie, flagged `HttpOnly` and `Path=/`.
- The JSON body returns the created user object under a `user` key: `{"user":{"email":"apitest01@example.com","username":"apitest01","bio":...,"image":...,"token":...}}`. TO CONFIRM: whether the Conduit-shape `user.token` field is still present in the body for backward-compat, OR omitted entirely because the token now lives only in the cookie (AC-1 forbids a body token being *stored in localStorage*, which is a client concern; the server body field itself is a design decision — confirm with dev).
- The response does NOT expose `password` or `hash`/`salt` fields.

**Pass/Fail criteria**: PASS if status is 2xx, an `HttpOnly` session cookie is set, and the body matches the Conduit user shape with no password material. Any missing cookie, missing `HttpOnly`, or leaked password field is a FAIL.
**Cleanup**: Delete the `apitest01` user from Postgres (or run against a disposable test DB). Delete `cookies01.txt`.

---

### TC-API-02 — Register with a duplicate email is rejected in Conduit error shape

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-5 / REQ-F-10 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | A user with email `dupe@example.com` already exists (create it first via TC-API-01 style call). |
| **Test data** | Body: `{"user":{"username":"dupe2","email":"dupe@example.com","password":"Passw0rd!23"}}` |

**Steps**
1. Ensure `dupe@example.com` exists: `curl -s -X POST http://localhost:3000/api/users -H "Content-Type: application/json" -d '{"user":{"username":"dupe1","email":"dupe@example.com","password":"Passw0rd!23"}}'`
2. Attempt to register again with the same email: `curl -i -X POST http://localhost:3000/api/users -H "Content-Type: application/json" -d '{"user":{"username":"dupe2","email":"dupe@example.com","password":"Passw0rd!23"}}'`
3. Inspect status and body.

**Expected result**
- Status `422` (Conduit validation error convention). TO CONFIRM: exact status the app uses for a duplicate.
- Body matches the Conduit error shape exactly: `{"errors":{"body":["..."]}}` — an object with an `errors` key whose value has a `body` array of message strings (e.g. `"email has already been taken"`).
- No `Set-Cookie` session cookie is issued on the failed registration.

**Pass/Fail criteria**: PASS if the second registration is rejected with a `{"errors":{"body":[...]}}` shaped body and no session cookie. A 2xx, a second created user, or any other error shape is a FAIL.
**Cleanup**: Delete the `dupe1` user. No `dupe2` should exist.

---

### TC-API-03 — Register with missing/invalid fields returns validation errors

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-5 / REQ-F-10 |
| **Type** | API |
| **Priority** | P2 |
| **Preconditions** | SUT running. |
| **Test data** | (a) empty password: `{"user":{"username":"noPass","email":"nopass@example.com","password":""}}`; (b) missing email: `{"user":{"username":"noEmail","password":"Passw0rd!23"}}`; (c) missing `user` wrapper: `{"username":"bad","email":"bad@example.com","password":"x"}` |

**Steps**
1. Send request (a) with `curl -i`.
2. Send request (b) with `curl -i`.
3. Send request (c) with `curl -i`.
4. Inspect each status and body.

**Expected result**
- Each returns a 4xx (expected `422`) and a `{"errors":{"body":[...]}}` shaped body naming the offending field(s).
- No user is created and no session cookie is set for any of the three.

**Pass/Fail criteria**: PASS if all three are rejected in the Conduit error shape with no user created and no cookie set. Any created user or non-conforming error body is a FAIL.
**Cleanup**: Verify none of `noPass`/`noEmail`/`bad` exist; delete if present.

---

### TC-API-04 — Login with valid credentials succeeds and sets an httpOnly cookie

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-5 / REQ-F-15, REQ-F-16 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | A registered user exists: `loginok@example.com` / `Passw0rd!23` (register it first). |
| **Test data** | Body: `{"user":{"email":"loginok@example.com","password":"Passw0rd!23"}}` |

**Steps**
1. Register the user: `curl -s -X POST http://localhost:3000/api/users -H "Content-Type: application/json" -d '{"user":{"username":"loginok","email":"loginok@example.com","password":"Passw0rd!23"}}'`
2. Log in: `curl -i -c cookies04.txt -X POST http://localhost:3000/api/users/login -H "Content-Type: application/json" -d '{"user":{"email":"loginok@example.com","password":"Passw0rd!23"}}'`
3. Inspect status, headers, body, and `cookies04.txt`.

**Expected result**
- Status `200`.
- A `Set-Cookie` header carrying the JWT session cookie, flagged `HttpOnly`.
- Body returns the `user` object in Conduit shape (email, username, bio, image, and — TO CONFIRM — token field policy per TC-API-01).
- No password material in the body.

**Pass/Fail criteria**: PASS if 200 with an `HttpOnly` cookie set and a Conduit-shaped user body. Missing cookie or leaked password material is a FAIL.
**Cleanup**: Delete `loginok` user; delete `cookies04.txt`.

---

### TC-API-05 — Login with wrong password is rejected in Conduit error shape (no cookie)

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-F-15 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | Registered user `loginok@example.com` / `Passw0rd!23` exists. |
| **Test data** | (a) wrong password: `{"user":{"email":"loginok@example.com","password":"WRONG!!!"}}`; (b) unknown email: `{"user":{"email":"ghost@example.com","password":"Passw0rd!23"}}` |

**Steps**
1. Send (a) with `curl -i -c bad05.txt`.
2. Send (b) with `curl -i -c bad05b.txt`.
3. Inspect each status, body, and cookie file.

**Expected result**
- Each returns a 4xx (expected `401` or `422` — TO CONFIRM: exact status; Conduit reference uses `422`/`403`).
- Body matches `{"errors":{"body":[...]}}` with a generic message (e.g. `"email or password is invalid"`) — the message MUST NOT disclose whether the email exists vs. the password is wrong.
- No session cookie is set for either.

**Pass/Fail criteria**: PASS if both are rejected in the Conduit error shape, with an identical/generic message for both wrong-password and unknown-email, and no cookie set. Distinct messages that reveal account existence, or any cookie set, is a FAIL.
**Cleanup**: Delete cookie files. Leave `loginok` for reuse or delete.

---

### TC-API-06 — Authenticated request with the session cookie resolves the correct current user

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-2, AC-5 / REQ-F-16, REQ-F-18 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | Registered user `whoami@example.com` / `Passw0rd!23` exists. |
| **Test data** | Login body: `{"user":{"email":"whoami@example.com","password":"Passw0rd!23"}}`. Current-user endpoint: `GET /api/user`. TO CONFIRM: exact current-user endpoint path (Conduit reference is `GET /api/user`). |

**Steps**
1. Register `whoami` then log in capturing the cookie: `curl -s -c cookies06.txt -X POST http://localhost:3000/api/users/login -H "Content-Type: application/json" -d '{"user":{"email":"whoami@example.com","password":"Passw0rd!23"}}'`
2. Call the current-user endpoint replaying the cookie only (no Authorization header): `curl -i -b cookies06.txt http://localhost:3000/api/user`
3. Inspect status and body.

**Expected result**
- Status `200`.
- Body returns the `user` object whose `email` is `whoami@example.com` and `username` is `whoami` — i.e. the cookie resolved to the correct user, not a different or default account.

**Pass/Fail criteria**: PASS if the cookie alone resolves the exact user that logged in. A wrong user, a 401, or a requirement for an Authorization header (instead of the cookie) is a FAIL.
**Cleanup**: Delete `whoami` user; delete `cookies06.txt`.

---

### TC-API-07 — Request to a protected endpoint with no/invalid cookie is unauthorized

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-16, REQ-F-18 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | SUT running. A protected endpoint is available. TO CONFIRM: which endpoint is protected (current user `GET /api/user`, or an update `PUT /api/user`) — confirm with dev. |
| **Test data** | (a) no cookie; (b) tampered cookie value `token=not.a.valid.jwt` |

**Steps**
1. Call the protected endpoint with no cookie: `curl -i http://localhost:3000/api/user`
2. Call it with a garbage cookie: `curl -i --cookie "token=not.a.valid.jwt" http://localhost:3000/api/user`
3. Inspect each status and body.

**Expected result**
- Each returns `401 Unauthorized` (TO CONFIRM: 401 vs 403 for the app's UnauthorizedError mapping).
- Body matches `{"errors":{"body":[...]}}`.
- No user data is returned.

**Pass/Fail criteria**: PASS if both are rejected with 401/403 and no user data leaks. A 200 or any returned user object is a FAIL.
**Cleanup**: None.

---

### TC-API-08 — Public endpoint passes through unauthenticated (soft auth)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-16 |
| **Type** | API |
| **Priority** | P2 |
| **Preconditions** | SUT running. A public endpoint that benefits from optional auth exists. TO CONFIRM: which endpoint is public-with-soft-auth (Conduit reference: `GET /api/articles`, `GET /api/profiles/:username`). |
| **Test data** | None. |

**Steps**
1. Call a public listing endpoint with no cookie: `curl -i http://localhost:3000/api/articles`
2. Inspect status and body.
3. (Optional) Repeat while logged in (with a valid cookie) and compare.

**Expected result**
- Status `200` for the unauthenticated call — the request passes through rather than being blocked (soft auth).
- Response is a valid Conduit payload (e.g. `{"articles":[...],"articlesCount":n}`); user-relative fields (e.g. `following`, `favorited`) default to `false` when unauthenticated.

**Pass/Fail criteria**: PASS if the public endpoint returns 200 without a cookie. A 401 on a public endpoint is a FAIL (soft auth broken).
**Cleanup**: None.

---

### TC-API-09 — Register/login response bodies conform to the Conduit user schema

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-F-10, REQ-F-15 |
| **Type** | API |
| **Priority** | P2 |
| **Preconditions** | SUT running. |
| **Test data** | Body: `{"user":{"username":"schema01","email":"schema01@example.com","password":"Passw0rd!23"}}` |

**Steps**
1. Register `schema01` and capture the body.
2. Verify the body is a JSON object with a single top-level `user` key.
3. Verify `user` contains at minimum: `email` (string), `username` (string), `bio` (string or null), `image` (string or null). TO CONFIRM: `token` field presence policy per TC-API-01.
4. Confirm no extra sensitive fields (`password`, `hash`, `salt`, internal `id` — TO CONFIRM whether `id` is intentionally exposed).

**Expected result**
- Body shape exactly matches the Conduit user response contract; no sensitive/internal fields leaked.

**Pass/Fail criteria**: PASS if the shape conforms and no sensitive fields are present. Missing required field or any leaked credential material is a FAIL.
**Cleanup**: Delete `schema01` user.

---

### TC-API-10 — Ported error classes surface as correctly-mapped Conduit error responses

| Field | Value |
|-------|-------|
| **Traces to** | AC-3, AC-5 / REQ-F-10 |
| **Type** | API |
| **Priority** | P2 |
| **Preconditions** | SUT running. This verifies AC-3's ported error hierarchy (`MyError`/`ForbiddenError`/`NotFoundError`/`UnauthorizedError`) is exercised through its **observable HTTP mapping** — black-box, never by reading source. |
| **Test data** | (a) UnauthorizedError: protected endpoint with no cookie; (b) NotFoundError: request a non-existent resource, e.g. `GET /api/profiles/definitely-no-such-user-xyz` (TO CONFIRM: a route that raises NotFoundError); (c) ForbiddenError: an action the authenticated user is not allowed to perform (TO CONFIRM: a route that raises ForbiddenError, if any exists within this story's surface — mark N/A if none). |

**Steps**
1. Trigger (a): `curl -i http://localhost:3000/api/user` with no cookie.
2. Trigger (b): `curl -i http://localhost:3000/api/profiles/definitely-no-such-user-xyz`
3. If a forbidden action is reachable, trigger (c) and capture the response.
4. Inspect each status and body.

**Expected result**
- (a) maps to `401` (UnauthorizedError); (b) maps to `404` (NotFoundError); (c) maps to `403` (ForbiddenError) if reachable.
- Every one of these error responses uses the SAME Conduit envelope `{"errors":{"body":[...]}}` — proving the shared error hierarchy renders consistently.
- No response leaks a stack trace or internal class name.

**Pass/Fail criteria**: PASS if each triggered error maps to its correct status AND all use the `{"errors":{"body":[...]}}` envelope with no stack trace. A wrong status, an inconsistent error shape, or a leaked stack trace is a FAIL. Mark (c) N/A with a note if no forbidden action exists in this story's surface.
**Cleanup**: None.
