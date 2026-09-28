# Security Test Steps — #26 Article Editor & Profile Page

**Purpose**: Verify the access-control and input-handling boundaries this story introduces — only an
authenticated author may create/edit/delete their own article, editing/deleting another user's
article is denied, the editor is unreachable while logged out, and untrusted input is handled safely.
Black-box, manual, executed against a locally built instance of the merged story. Maps each case to
the AIRE Security Baseline where a rule applies.

**Scope**: Authentication gate on `/editor` and `/editor/[slug]`; authorization (ownership) on article
create/edit/delete via the article API; IDOR on article slugs; input handling in the editor form;
sensitive-data exposure on the profile page. Observable behaviour only — no source code read.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | PR #34 — https://github.com/revanta-biswas/conduit-helix-test/pull/34 |
| Confirm the story is in the build | `git log --oneline \| grep -i "1.8"` (or search for the PR #34 merge commit) |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | http://localhost:3000 |
| Local services that must be up | PostgreSQL (via Sequelize) reachable by the app; app server running on :3000 |
| Test data / accounts to seed | An "author" account, a "second user" account, and ≥1 article owned by the author |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-SEC-01 — Editor requires authentication (logged-out access blocked)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-22 |
| **Type** | Security |
| **Priority** | P1 |
| **Security Baseline** | Access control (SECURITY-07) — authentication required for protected UI |
| **Preconditions** | SUT running; browser logged OUT (cleared cookies) |
| **Test data** | None |

**Steps**
1. In a logged-out browser, navigate directly to http://localhost:3000/editor.
2. Then navigate directly to http://localhost:3000/editor/some-existing-slug.
3. Observe the resulting URL/page in each case.

**Expected result**
- Both editor routes are unreachable while logged out: the browser is redirected to `/login` (or an
  equivalent block), with no editable, submittable form served to an anonymous user.

**Pass/Fail criteria**: PASS if a logged-out user cannot reach either editor route. Any usable editor
form for an anonymous user is a FAIL.
**Cleanup**: None.

---

### TC-SEC-02 — Article create requires an authenticated session (no session -> rejected)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-3 / REQ-F-22 |
| **Type** | Security |
| **Priority** | P1 |
| **Security Baseline** | Access control (SECURITY-07) |
| **Preconditions** | SUT running; logged OUT |
| **Test data** | Attempted article — Title: `Anon Article`, Body: `x` |

**Steps**
1. If any editor form is reachable while logged out, attempt to submit an article.
2. Alternatively, replay the create request with the session cookie removed (DevTools -> copy as
   fetch, delete the auth cookie, resend). TO CONFIRM: exact session cookie name with the dev/BA.
3. Observe the response and whether an article was created.

**Expected result**
- A create attempt without a valid session is rejected (401/403 from `/api/articles`, or blocked at
  the page), and no article is created (verify it is not in the global feed).

**Pass/Fail criteria**: PASS if no anonymous create succeeds. Any article created without a valid
session is a FAIL.
**Cleanup**: Delete any article wrongly created.

---

### TC-SEC-03 — Author can only edit their OWN article (authorization enforced)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-4 / REQ-F-22 |
| **Type** | Security |
| **Priority** | P1 |
| **Security Baseline** | Access control / IDOR (SECURITY-07) |
| **Preconditions** | SUT running; logged in as the second user; a foreign article (owned by the author) with a known slug |
| **Test data** | Second-user session; foreign slug: `<author-owned-slug>`; edit payload changing the title |

**Steps**
1. Log in as the second user.
2. Navigate to http://localhost:3000/editor/`<foreign-slug>` and attempt to edit and submit.
3. Also replay a PUT to `/api/articles/<foreign-slug>` directly with the second user's session
   (DevTools -> copy as fetch, modify body, resend).
4. Re-check the article as its owner.

**Expected result**
- The non-owner edit is denied both via the UI and via a direct API replay: the API returns 401/403
  (or 422/404 if ownership is masked), and the article's content is unchanged for its owner.

**Pass/Fail criteria**: PASS if a non-owner cannot persist any edit through either path. Any accepted
non-owner edit is a FAIL.
**Cleanup**: Restore the article if it changed.

---

### TC-SEC-04 — Author can only delete their OWN article (authorization enforced)

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-F-22 |
| **Type** | Security |
| **Priority** | P1 |
| **Security Baseline** | Access control / IDOR (SECURITY-07) |
| **Preconditions** | SUT running; logged in as the second user; a foreign article exists |
| **Test data** | Second-user session; foreign slug: `<author-owned-slug>` |

**Steps**
1. Log in as the second user.
2. Attempt to delete the foreign article via any UI control on the editor/article view.
3. Replay a DELETE to `/api/articles/<foreign-slug>` directly with the second user's session.
4. Confirm the article still exists (as its owner) in the feed/profile.

**Expected result**
- The non-owner delete is denied via UI and direct API replay (401/403), and the article remains
  present in the global feed and the owner's profile.

**Pass/Fail criteria**: PASS if a non-owner cannot delete the article. Any successful non-owner
deletion is a FAIL.
**Cleanup**: Re-create the article if it was wrongly deleted.

---

### TC-SEC-05 — IDOR: manipulating the slug in the editor URL does not grant edit rights

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-4 / REQ-F-22 |
| **Type** | Security (negative/boundary) |
| **Priority** | P1 |
| **Security Baseline** | IDOR / access control (SECURITY-07) |
| **Preconditions** | SUT running; logged in as the second user |
| **Test data** | Several foreign/guessed slugs including a valid author-owned slug and a random string |

**Steps**
1. Log in as the second user.
2. Iterate `/editor/<slug>` over: a valid foreign slug, a guessed/sequential-looking slug, and a
   nonexistent slug.
3. For each, attempt to load and submit an edit.

**Expected result**
- For a foreign slug: edit is denied (per TC-SEC-03). For a nonexistent slug: a graceful not-found/empty
  state, no server error. No slug value grants a non-owner the ability to persist an edit.

**Pass/Fail criteria**: PASS if no slug manipulation yields an unauthorized edit and unknown slugs are
handled gracefully. Any bypass or 500 is a FAIL.
**Cleanup**: None.

---

### TC-SEC-06 — Editor input handling: script/markup in article fields is not executed (stored XSS)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-3 / REQ-F-22 |
| **Type** | Security (negative/boundary) |
| **Priority** | P1 |
| **Security Baseline** | Input validation / output encoding (SECURITY-04) |
| **Preconditions** | SUT running; logged in as the author |
| **Test data** | Title: `XSS <script>alert('t')</script>`; Body: `Body <img src=x onerror=alert(1)> **md**`; Tag: `<b>tag</b>` |

**Steps**
1. Create an article with the Test data values in the editor.
2. Open the created article's view page and the global feed/profile listings.
3. Observe whether any injected script executes (alert dialog) and how the markup renders.

**Expected result**
- No injected script executes anywhere the values are displayed (article view, feed, profile). The
  content is rendered as inert text or safely-sanitized markdown/HTML. TO CONFIRM: whether the body
  is rendered as sanitized Markdown or plain text with the dev/BA.

**Pass/Fail criteria**: PASS if no injected script executes on any surface. Any alert/script execution
is a FAIL (raise a security defect).
**Cleanup**: Delete the created article.

---

### TC-SEC-07 — Editor input handling: over-length and empty-boundary inputs are handled safely

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-4 / REQ-F-22 |
| **Type** | Security (boundary) |
| **Priority** | P2 |
| **Security Baseline** | Input validation (SECURITY-04) |
| **Preconditions** | SUT running; logged in as the author |
| **Test data** | Title: a 10,000-character string; Body: empty; Tags: 200 tags; also a title of only whitespace `   ` |

**Steps**
1. Attempt to create articles with each boundary input in turn.
2. Observe the response and any error message.

**Expected result**
- Each boundary input is either accepted safely or rejected with a visible, human-readable validation
  message and no server crash / stack trace. A whitespace-only title is treated as blank (rejected).
  TO CONFIRM: documented field length limits with the dev/BA.

**Pass/Fail criteria**: PASS if all boundary inputs are handled without a 500/crash and blank-equivalent
titles are rejected. Any unhandled crash is a FAIL.
**Cleanup**: Delete any created articles.

---

### TC-SEC-08 — Profile page does not expose other users' sensitive data

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-23 |
| **Type** | Security |
| **Priority** | P2 |
| **Security Baseline** | Sensitive data exposure / error handling (SECURITY-13, SECURITY-15) |
| **Preconditions** | SUT running; logged in as the author; viewing another user's profile |
| **Test data** | Target username: `e2e_second` |

**Steps**
1. Navigate to http://localhost:3000/profile/e2e_second.
2. In DevTools -> Network, inspect the profile fetch response body.
3. View page source for any embedded server data.

**Expected result**
- The profile response exposes only public profile fields (username, bio, image, following flag) and
  the target's public articles — no password hash, no email, no auth token, no internal error/stack.

**Pass/Fail criteria**: PASS if only public fields are present. Any password/email/token/stack in the
response or page is a FAIL (raise a security defect).
**Cleanup**: None.
