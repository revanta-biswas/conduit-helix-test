# E2E Test Steps — #24 Auth Pages & Session (Login, Register, Settings)

**Purpose**: Verify the complete user-visible auth journeys implied by the acceptance criteria — a
user can register through the page and land logged in, log in and update their settings, keep a
session across navigation/refresh, and log out into a logged-out state. Black-box, manual,
executed against a locally built instance of the merged story.

**Scope**: The `/login`, `/register`, and `/settings` pages and the cookie-based session that ties
them together (browser-observable behaviour only — no source code read).

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | PR #33 — https://github.com/revanta-biswas/conduit-helix-test/pull/33 |
| Confirm the story is in the build | `git log --oneline \| grep -i "1.6"` (or search for PR #33 merge commit) |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | http://localhost:3000 |
| Local services that must be up | PostgreSQL (via Sequelize) reachable by the app; app dev/prod server running on :3000 |
| Test data / accounts to seed | One pre-existing account for login tests (see per-case Test data). Register tests create fresh accounts. |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-E2E-01 — Register through the page and land logged in

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-24 |
| **Type** | E2E |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT running on http://localhost:3000; PostgreSQL up; browser with a fresh profile / cleared cookies and localStorage; the username/email below are not already registered |
| **Test data** | Username: `e2e_newuser_01`; Email: `e2e_newuser_01@example.com`; Password: `Passw0rd!123` |

**Steps**
1. Open a fresh browser session and navigate to http://localhost:3000/register.
2. Enter the username, email, and password from Test data into the corresponding fields.
3. Submit the registration form (click the Sign up / submit button).
4. Wait for the page to respond and any navigation to settle.

**Expected result**
- Registration succeeds; the app transitions to a logged-in state (e.g. the header shows the
  username / a "Your Feed" / "Settings" / "New Article" affordance rather than "Sign in" / "Sign up").
- The user is redirected away from `/register` (typically to the home route). TO CONFIRM: exact
  post-register redirect target with the dev/BA.

**Pass/Fail criteria**: PASS if the account is created and the browser is left in a logged-in state
without a second manual login step. Any error, or being left on `/register` unauthenticated, is a FAIL.
**Cleanup**: Delete the `e2e_newuser_01` account from PostgreSQL (or via an admin path) so the case can be re-run.

---

### TC-E2E-02 — Register is rejected when username/email is already taken

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-24 |
| **Type** | E2E (negative) |
| **Priority** | P1 |
| **Preconditions** | SUT running; an account already exists with the username/email below (seed it, or run TC-E2E-01 first) |
| **Test data** | Duplicate username: `e2e_newuser_01`; Email: `e2e_newuser_01@example.com`; Password: `Passw0rd!123` |

**Steps**
1. Navigate to http://localhost:3000/register in a logged-out browser.
2. Enter the already-registered username and email plus any password.
3. Submit the form.

**Expected result**
- Registration fails; a visible, human-readable validation/error message is shown on the page
  (e.g. "username has already been taken" / "email has already been taken").
- The browser stays on `/register` and remains in a logged-out state (no session established).

**Pass/Fail criteria**: PASS if the duplicate is rejected with a visible error and no session is
created. Silent success, a blank page, or an unhandled crash is a FAIL.
**Cleanup**: None (no new account created).

---

### TC-E2E-03 — Log in, update Settings, and see the change persist

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-2 / REQ-F-24, REQ-F-25 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | SUT running; a valid account exists; browser logged out at start |
| **Test data** | Account — Email: `e2e_settings@example.com`, Password: `Passw0rd!123`. New bio: `Updated bio via E2E`; New image URL: `https://example.com/avatar.png`; New email: `e2e_settings_new@example.com` |

**Steps**
1. Navigate to http://localhost:3000/login and log in with the account credentials.
2. Confirm you are logged in (header shows the logged-in affordances).
3. Navigate to http://localhost:3000/settings.
4. Update the bio, image URL, and email fields with the Test data values.
5. Submit the settings update form.
6. Wait for the update to complete, then reload the `/settings` page.

**Expected result**
- Login succeeds and the settings form is reachable and pre-populated with the current profile.
- The settings update is accepted (visible success state / no error); a PUT to `/api/user` is
  issued (verifiable in DevTools -> Network as a 2xx response). TO CONFIRM: exact success UX
  (redirect vs. inline confirmation) with the dev/BA.
- After reload, the updated bio, image, and email are reflected in the form fields.

**Pass/Fail criteria**: PASS if all three fields are updated and the change survives a page reload.
Any field not persisting, or an error on submit, is a FAIL.
**Cleanup**: Revert the account's bio/image/email to their original values (via Settings or PostgreSQL).

---

### TC-E2E-04 — Settings update rejected with an invalid image URL

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-25 |
| **Type** | E2E (negative/boundary) |
| **Priority** | P2 |
| **Preconditions** | SUT running; logged in with a valid account |
| **Test data** | Invalid image value: `not-a-valid-url` (also try an empty-with-spaces value `   `) |

**Steps**
1. Log in and navigate to http://localhost:3000/settings.
2. Replace the image URL field with `not-a-valid-url`.
3. Submit the settings update.

**Expected result**
- The update is rejected with a visible validation/error message, OR the field is sanitised/ignored
  per the documented contract. TO CONFIRM: whether image-URL format is validated client-side,
  server-side, or not at all — confirm expected behaviour with the dev/BA. Record the actual
  observed behaviour.
- The user is not left in a broken state (no crash, form still usable).

**Pass/Fail criteria**: PASS if the invalid input is handled predictably (rejected with a message or
safely ignored) and matches the confirmed contract. An unhandled error / app crash is a FAIL.
**Cleanup**: Restore a valid image URL on the account.

---

### TC-E2E-05 — Session persists across navigation and browser refresh

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-F-28 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | SUT running; logged in with a valid account |
| **Test data** | Any valid account |

**Steps**
1. Log in at http://localhost:3000/login.
2. Navigate between routes: home (`/`), then `/settings`, then back to home.
3. Perform a full browser refresh (F5 / reload) on each of at least two different routes.
4. Close the tab and reopen http://localhost:3000/ in the same browser session (cookie not expired).

**Expected result**
- Throughout all navigation and refreshes, the app remains in a logged-in state (logged-in header
  affordances persist); no re-login is required.
- `/settings` remains directly reachable while the session is valid.

**Pass/Fail criteria**: PASS if the session survives navigation, refresh, and tab reopen without a
re-login prompt. Being logged out on refresh/navigation is a FAIL.
**Cleanup**: Log out.

---

### TC-E2E-06 — Log out clears the session and produces a logged-out state

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-F-28 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | SUT running; logged in with a valid account |
| **Test data** | Any valid account |

**Steps**
1. Log in at http://localhost:3000/login.
2. Trigger logout (the logout control in the header/settings). TO CONFIRM: exact logout control
   location with the dev/BA.
3. Observe the resulting page.
4. Attempt to navigate directly to http://localhost:3000/settings.

**Expected result**
- After logout the app shows a logged-out state (header shows "Sign in" / "Sign up"; logged-in
  affordances gone) and redirects to a logged-out landing (e.g. home or `/login`).
- Navigating to `/settings` while logged out redirects to the login page (not the settings form).

**Pass/Fail criteria**: PASS if logout returns the app to a logged-out state and `/settings` is no
longer accessible without logging in. Remaining logged in, or `/settings` still rendering the form,
is a FAIL.
**Cleanup**: None.
