# Security Test Steps — #24 Auth Pages & Session (Login, Register, Settings)

**Purpose**: Verify the security-relevant behaviour of the auth pages and session: the session is
carried in a server-verified (httpOnly) cookie and NOT in localStorage, credentials are validated,
logout clears the session cookie, protected routes are not reachable without a session, and no
sensitive tokens leak into client-observable storage. Black-box, manual, browser-observable only.

**Scope**: Session storage location, cookie attributes, credential validation, protected-route
access control, and token leakage — all verified from the browser (DevTools), never from source.

**Security Baseline mapping**: cases here map to session-integrity / session-management and
authentication rules of the AIRE Security Baseline (session in a server-verified cookie, not client
storage; session invalidated on logout; auth required for protected surfaces). TO CONFIRM: exact
SECURITY-xx rule numbers with the security reviewer.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | PR #33 — https://github.com/revanta-biswas/conduit-helix-test/pull/33 |
| Confirm the story is in the build | `git log --oneline \| grep -i "1.6"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | http://localhost:3000 |
| Local services that must be up | PostgreSQL (via Sequelize); app server on :3000 |
| Test data / accounts to seed | One valid account for login; register cases create fresh accounts |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-SEC-01 — No auth token stored in localStorage (cookie-based session)

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-28 |
| **Type** | Security |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT running; browser with cleared cookies + localStorage; a valid account to log in with |
| **Test data** | Any valid account |

**Steps**
1. Open the browser DevTools -> Application (Chrome) / Storage (Firefox) tab so both Local Storage
   and Cookies for http://localhost:3000 are visible.
2. Log in at http://localhost:3000/login with the valid account.
3. In DevTools -> Application -> Local Storage -> http://localhost:3000, inspect every key/value.
4. In DevTools -> Application -> Session Storage -> http://localhost:3000, inspect every key/value.
5. In DevTools -> Application -> Cookies -> http://localhost:3000, inspect the cookies.

**Expected result**
- Local Storage contains NO auth token / JWT / session identifier (no `jwt`, `token`, `user`, `auth`
  key holding a credential). Session Storage likewise holds no auth credential.
- A session cookie is present in the Cookies list (the server-verified session).

**Pass/Fail criteria**: PASS only if no auth token appears in Local Storage or Session Storage AND a
session cookie exists. Any auth token/JWT found in localStorage/sessionStorage is a FAIL (AC-3 violation).
**Cleanup**: Log out; clear storage.

---

### TC-SEC-02 — Session cookie is httpOnly and not readable from JavaScript

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-28 |
| **Type** | Security |
| **Priority** | P1 |
| **Preconditions** | SUT running; logged in with a valid account; DevTools open |
| **Test data** | Any valid account |

**Steps**
1. While logged in, open DevTools -> Application -> Cookies -> http://localhost:3000.
2. Locate the session cookie and inspect its attributes column: HttpOnly, Secure, SameSite, Path,
   Expires/Max-Age.
3. Open DevTools -> Console and run `document.cookie`.

**Expected result**
- The session cookie shows `HttpOnly = true`. `SameSite` is set (Lax or Strict). TO CONFIRM: exact
  session cookie name and whether `Secure` is expected on plain-HTTP localhost with the dev/security
  reviewer.
- `document.cookie` in the Console does NOT return the session cookie value (because it is httpOnly).

**Pass/Fail criteria**: PASS if the session cookie is HttpOnly and is absent from `document.cookie`.
A session cookie readable via `document.cookie` (not httpOnly) is a FAIL.
**Cleanup**: Log out.

---

### TC-SEC-03 — Login with wrong password is rejected and creates no session

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-24 |
| **Type** | Security (negative) |
| **Priority** | P1 |
| **Preconditions** | SUT running; a valid account exists; browser logged out; DevTools open |
| **Test data** | Email: valid account email; Password: `WrongPassword!999` (deliberately incorrect) |

**Steps**
1. Navigate to http://localhost:3000/login.
2. Enter the correct email but the wrong password.
3. Submit the form.
4. Inspect DevTools -> Application -> Cookies and Local Storage after the failed attempt.

**Expected result**
- Login fails with a visible, generic error message (e.g. "email or password is invalid"); the
  message must NOT reveal whether the email exists vs. the password is wrong.
- No session cookie is set and no auth token appears in localStorage; the app stays logged out on `/login`.

**Pass/Fail criteria**: PASS if login is rejected with a generic error and no session is established.
A session being created, or an error that discloses which field was wrong, is a FAIL.
**Cleanup**: None.

---

### TC-SEC-04 — Protected route `/settings` is not reachable without a session

| Field | Value |
|-------|-------|
| **Traces to** | AC-3, AC-5 / REQ-F-25, REQ-F-28 |
| **Type** | Security (access control) |
| **Priority** | P1 |
| **Preconditions** | SUT running; browser with NO session (cleared cookies) |
| **Test data** | None |

**Steps**
1. In a logged-out browser (no session cookie), navigate directly to http://localhost:3000/settings.
2. Observe the resulting page.
3. Additionally, if a session cookie value is visible, delete only the session cookie via DevTools
   while on `/settings` and refresh.

**Expected result**
- With no session, `/settings` redirects to the login page (or an equivalent logged-out state); the
  settings form and the current profile data are NOT rendered.

**Pass/Fail criteria**: PASS if `/settings` is inaccessible without a session and redirects to login.
Rendering the settings form or exposing profile data to an unauthenticated visitor is a FAIL.
**Cleanup**: None.

---

### TC-SEC-05 — Logout clears the session cookie server-side

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-F-28 |
| **Type** | Security |
| **Priority** | P1 |
| **Preconditions** | SUT running; logged in with a valid account; DevTools open |
| **Test data** | Any valid account |

**Steps**
1. Log in and confirm the session cookie is present in DevTools -> Application -> Cookies.
2. Note the session cookie value.
3. Trigger logout.
4. Re-inspect DevTools -> Application -> Cookies for http://localhost:3000.
5. Attempt to reuse the old session: with the app logged out, navigate to `/settings`.

**Expected result**
- After logout the session cookie is removed or invalidated (cleared value / expired). The app is
  logged out and `/settings` redirects to login (the old session no longer grants access).

**Pass/Fail criteria**: PASS if the session cookie is cleared/invalidated on logout and no longer
authorises access to protected routes. A still-valid session cookie after logout is a FAIL.
**Cleanup**: None.

---

### TC-SEC-06 — Session survives refresh via the cookie (not client storage)

| Field | Value |
|-------|-------|
| **Traces to** | AC-3, AC-4 / REQ-F-28 |
| **Type** | Security |
| **Priority** | P2 |
| **Preconditions** | SUT running; logged in; DevTools open |
| **Test data** | Any valid account |

**Steps**
1. Log in. In DevTools, confirm Local Storage holds no auth token and a session cookie exists.
2. Refresh the page (F5).
3. Immediately re-inspect Local Storage and Cookies.

**Expected result**
- The user stays logged in after refresh, driven by the persisted session cookie — Local Storage
  still holds no auth token before or after the refresh.

**Pass/Fail criteria**: PASS if the session survives refresh with the credential living only in the
cookie. If a token appears in localStorage, or the session is lost on refresh, that is a FAIL.
**Cleanup**: Log out.

---

### TC-SEC-07 — Injection-style input in auth fields is handled safely

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-2 / REQ-F-24, REQ-F-25 |
| **Type** | Security (negative/boundary) |
| **Priority** | P2 |
| **Preconditions** | SUT running; browser logged out (for login/register) and a valid account for settings |
| **Test data** | XSS probe: `<script>alert(1)</script>`; SQL-ish probe: `' OR '1'='1`. Use in the username/email/bio fields as appropriate. |

**Steps**
1. On `/register`, enter the XSS probe as the username and the SQL-ish probe combined with a valid
   email format, then submit.
2. On `/login`, enter the SQL-ish probe in the email field with any password and submit.
3. Logged in, on `/settings`, enter the XSS probe in the bio field and submit; then view any page
   that renders the bio.

**Expected result**
- No script executes (no alert dialog) at any point; probes are rejected by validation or stored and
  rendered as inert, escaped text.
- No authentication is bypassed by the SQL-ish probe on `/login` (login still fails).
- No server error page / stack trace is exposed to the browser.

**Pass/Fail criteria**: PASS if injection probes neither execute nor bypass auth nor surface a raw
error. A fired alert, an auth bypass, or a leaked stack trace is a FAIL.
**Cleanup**: Delete any test account created; restore the settings account's bio.
