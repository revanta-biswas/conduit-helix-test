# Security Test Steps — #20 Auth API: Register, Login & httpOnly Cookie Session

**Purpose**: Verify the auth surface against Security Baseline concerns: httpOnly/Secure cookie flags, no token stored in a body field that lands in localStorage, safe credential handling, injection inputs rejected, account-enumeration resistance, and no sensitive data in logs or responses.
**Scope**: Register, login, cookie issuance, cookie verification on protected routes, and JWT handling.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | [PR #29](https://github.com/revanta-biswas/conduit-helix-test/pull/29) |
| Confirm the story is in the build | `git log --oneline \| grep -i "#29\|1.2\|auth"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | `http://localhost:3000`, API under `/api/` |
| Local services that must be up | PostgreSQL (via Sequelize), schema from existing Sequelize CLI migrations |
| Test data / accounts to seed | A known user `sec@example.com` / `Passw0rd!23` (register it as part of setup) |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log functional failures against a system that never started.

**Security Baseline mapping**: cookie flags & session integrity → SECURITY-12; JWT handling → SECURITY-09; credential management / no secrets in responses → SECURITY-11; input validation / injection → SECURITY-04; logging (no sensitive data) → SECURITY-02; error handling (no info disclosure) → SECURITY-15. TO CONFIRM: exact rule numbers against `extensions/security/baseline/security-baseline.md` if precise citation is required.

---

### TC-SEC-01 — Session cookie carries HttpOnly (and Secure/SameSite) flags

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-NF-01, REQ-NF-03 |
| **Type** | Security |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT running. Baseline rule SECURITY-12 (session integrity / cookie flags). |
| **Test data** | Login body for `sec@example.com` / `Passw0rd!23`. |

**Steps**
1. Log in and capture full response headers: `curl -i -c sec01.txt -X POST http://localhost:3000/api/users/login -H "Content-Type: application/json" -d '{"user":{"email":"sec@example.com","password":"Passw0rd!23"}}'`
2. Read the raw `Set-Cookie` header line from the response.
3. Inspect the flags on the session cookie.

**Expected result**
- `Set-Cookie` includes `HttpOnly`.
- `Set-Cookie` includes `SameSite` (expected `Lax` or `Strict`). TO CONFIRM: intended SameSite value.
- `Set-Cookie` includes `Secure` when served over HTTPS. Note: on a local `http://localhost` run `Secure` may be intentionally omitted; record the observed value and flag if `Secure` is absent in a production-config run. TO CONFIRM: whether `Secure` is set unconditionally or environment-gated.
- Cookie has a bounded `Max-Age`/`Expires` (not a never-expiring session). TO CONFIRM: intended lifetime.

**Pass/Fail criteria**: PASS if `HttpOnly` is present on the session cookie (and `SameSite` set). Absence of `HttpOnly` is a FAIL (blocker — the story's core security control).
**Cleanup**: Delete `sec01.txt`.

---

### TC-SEC-02 — JWT is not returned in a body field intended for localStorage

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-NF-01 |
| **Type** | Security |
| **Priority** | P1 |
| **Preconditions** | SUT running. Baseline SECURITY-09 (JWT) / SECURITY-12. |
| **Test data** | Register/login for a fresh user. |

**Steps**
1. Register and log in; capture the JSON body.
2. Inspect whether a JWT string is present in the body.
3. If a `user.token` field exists, confirm it is the documented Conduit backward-compat field only. Then, in a browser, complete a login through the app UI and inspect `localStorage` and `sessionStorage` via DevTools > Application.

**Expected result**
- The authenticated session is carried by the httpOnly cookie.
- The client does NOT persist the JWT in `localStorage`/`sessionStorage`. TO CONFIRM: AC-1 states the token must not be "returned in a JSON body field stored in localStorage" — confirm with dev whether the body `token` field is removed entirely, or retained but never persisted client-side. Either satisfies the intent so long as nothing lands in localStorage.

**Pass/Fail criteria**: PASS if no JWT is found in browser localStorage/sessionStorage after login. A JWT persisted in localStorage is a FAIL.
**Cleanup**: Clear browser storage; delete the test user.

---

### TC-SEC-03 — Passwords and secrets are never echoed in responses

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-5 / REQ-NF-01 |
| **Type** | Security |
| **Priority** | P1 |
| **Preconditions** | SUT running. Baseline SECURITY-11 (credential management). |
| **Test data** | Register/login/current-user for `sec@example.com`. |

**Steps**
1. Capture the register, login, and `GET /api/user` response bodies.
2. Search each body for `password`, the actual password value, `hash`, `salt`, and any JWT signing secret.

**Expected result**
- No response contains the plaintext password, a password hash/salt, or any signing secret.

**Pass/Fail criteria**: PASS if none of the sensitive tokens appear in any response body. Any occurrence is a FAIL (blocker).
**Cleanup**: None.

---

### TC-SEC-04 — Credentials and tokens are absent from server logs

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-5 / REQ-NF-01 |
| **Type** | Security |
| **Priority** | P2 |
| **Preconditions** | SUT running with its console/log output captured. Baseline SECURITY-02 (logging). |
| **Test data** | One register and one failed-login attempt for `sec@example.com`. |

**Steps**
1. Start capturing the app's stdout/stderr (the terminal running the local server).
2. Perform a successful register, a successful login, and a failed login (wrong password).
3. Search the captured log output for the plaintext password, the JWT value, and the raw cookie value.

**Expected result**
- No log line contains the plaintext password, the issued JWT, or the raw session cookie value.

**Pass/Fail criteria**: PASS if none of these appear in logs. Any credential or token in logs is a FAIL.
**Cleanup**: Discard the captured log; delete test user if created.

---

### TC-SEC-05 — Injection-style inputs are rejected/neutralized, not executed

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-5 / REQ-NF-01 |
| **Type** | Security |
| **Priority** | P1 |
| **Preconditions** | SUT running on Postgres via Sequelize. Baseline SECURITY-04 (input validation). |
| **Test data** | (a) SQL injection in email: `{"user":{"email":"' OR '1'='1","password":"x"}}`; (b) SQL injection in login: `{"user":{"email":"admin'--","password":"anything"}}`; (c) NoSQL/operator style: `{"user":{"email":{"$ne":null},"password":{"$ne":null}}}`; (d) XSS payload as username on register: `{"user":{"username":"<script>alert(1)</script>","email":"xss1@example.com","password":"Passw0rd!23"}}` |

**Steps**
1. Send (a) to `POST /api/users/login` with `curl -i`.
2. Send (b) to `POST /api/users/login` with `curl -i`.
3. Send (c) to `POST /api/users/login` with `curl -i`.
4. Send (d) to `POST /api/users` with `curl -i`.
5. Inspect status and body for each.

**Expected result**
- (a),(b),(c): rejected as invalid credentials or a validation error in `{"errors":{"body":[...]}}` shape — never a successful login and never a 500/stack trace. The injection does not authenticate any account.
- (c): the non-string email/password is rejected by input validation (not passed to the query engine).
- (d): if the username is accepted, the stored/returned value is the literal string (escaped when later rendered); if rejected, a validation error. Either way, no script executes and no 500 occurs.

**Pass/Fail criteria**: PASS if all four are safely rejected/neutralized with proper status and no server error or unintended authentication. A successful injection-based login, a 500 with a DB stack trace, or an unescaped script reflected raw is a FAIL.
**Cleanup**: Delete any user created by (d).

---

### TC-SEC-06 — Login does not enable account enumeration

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-NF-01 |
| **Type** | Security |
| **Priority** | P2 |
| **Preconditions** | Known user `sec@example.com` exists; `ghost@example.com` does not. Baseline SECURITY-15 (error handling / info disclosure). |
| **Test data** | (a) existing email + wrong password; (b) non-existing email + any password. |

**Steps**
1. Send (a): `curl -i -X POST http://localhost:3000/api/users/login -H "Content-Type: application/json" -d '{"user":{"email":"sec@example.com","password":"WRONG!!!"}}'`
2. Send (b): `curl -i -X POST http://localhost:3000/api/users/login -H "Content-Type: application/json" -d '{"user":{"email":"ghost@example.com","password":"WRONG!!!"}}'`
3. Compare status codes and message bodies.

**Expected result**
- Both return the same status and the same generic message (e.g. `"email or password is invalid"`).
- Neither response nor its timing clearly discloses whether the email exists.

**Pass/Fail criteria**: PASS if the two responses are indistinguishable in status and message. Different messages/statuses that reveal account existence is a FAIL.
**Cleanup**: None.

---

### TC-SEC-07 — Tampered/expired JWT cookie is rejected

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-18, REQ-NF-01 |
| **Type** | Security |
| **Priority** | P1 |
| **Preconditions** | A valid session cookie captured for `sec@example.com`; a protected endpoint identified. Baseline SECURITY-09 (JWT). |
| **Test data** | (a) valid cookie with its signature segment altered by one character; (b) a JWT signed with a different/wrong secret (if craftable); (c) a well-formed JWT with `exp` in the past (if craftable). TO CONFIRM: cookie name and whether crafting b/c is feasible without the secret — if not, run (a) only. |

**Steps**
1. Capture a valid session cookie from a real login.
2. Modify the last character of the JWT signature segment and replay it against the protected endpoint: `curl -i --cookie "token=<TAMPERED_JWT>" http://localhost:3000/api/user`
3. If feasible, repeat with (b) a wrong-secret JWT and (c) an expired JWT.

**Expected result**
- Each tampered/expired token is rejected with `401` (or `403`), returning `{"errors":{"body":[...]}}` and no user data.
- A signature-altered token is NOT accepted (signature is verified server-side).

**Pass/Fail criteria**: PASS if all tampered/expired tokens are rejected. Any acceptance of an invalid-signature or expired token is a FAIL (blocker).
**Cleanup**: None.

---

### TC-SEC-08 — Protected route enforces authentication (cannot be bypassed)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-16, REQ-F-18 |
| **Type** | Security |
| **Priority** | P1 |
| **Preconditions** | A protected endpoint identified (TO CONFIRM which). Baseline SECURITY-06 (access control). |
| **Test data** | (a) no cookie; (b) empty cookie `token=`; (c) an Authorization header only, no cookie (should not substitute for the cookie session unless documented). |

**Steps**
1. Call the protected endpoint with no cookie.
2. Call it with `--cookie "token="`.
3. Call it with `-H "Authorization: Token abc.def.ghi"` and no cookie.
4. Inspect each status.

**Expected result**
- (a) and (b): `401`/`403`, no data returned.
- (c): TO CONFIRM whether a Bearer/Token header is still an accepted auth path or whether only the cookie is honored — if only the cookie is honored, this must also be `401`.

**Pass/Fail criteria**: PASS if no unauthenticated variant returns protected data. Any bypass returning user data without a valid cookie is a FAIL.
**Cleanup**: None.
