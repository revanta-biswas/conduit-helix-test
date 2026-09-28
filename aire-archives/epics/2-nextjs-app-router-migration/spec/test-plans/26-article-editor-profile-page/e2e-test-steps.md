# E2E Test Steps — #26 Article Editor & Profile Page

**Purpose**: Verify the complete user-visible journeys implied by the acceptance criteria — an
author creates an article and is redirected to it (and it appears in the global feed and their
profile), edits an existing article with a pre-filled form that persists changes, deletes an
article so it disappears everywhere, and views their own vs. another user's profile with working
follow/unfollow and the My Articles / Favorited tabs. Black-box, manual, executed against a locally
built instance of the merged story.

**Scope**: The `/editor`, `/editor/[slug]`, and `/profile/[username]` pages and their end-to-end
interaction with the article and profile APIs, the global feed, and the profile views
(browser-observable behaviour only — no source code read).

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | PR #34 — https://github.com/revanta-biswas/conduit-helix-test/pull/34 |
| Confirm the story is in the build | `git log --oneline \| grep -i "1.8"` (or search for the PR #34 merge commit) |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | http://localhost:3000 |
| Local services that must be up | PostgreSQL (via Sequelize) reachable by the app; app dev/prod server running on :3000 |
| Test data / accounts to seed | Two pre-existing accounts — an "author" account and a "second user" account (see per-case Test data). Article-create tests generate fresh articles. |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-E2E-01 — Create an article and get redirected to its article view page

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-3 / REQ-F-22 |
| **Type** | E2E |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT running on http://localhost:3000; PostgreSQL up; logged in as the author account; browser with the author's session active |
| **Test data** | Author login — Email: `e2e_author@example.com`, Password: `Passw0rd!123`. Article — Title: `E2E Create Flow Article`; Description (about): `An article created by the E2E create test`; Body: `# Heading\n\nThis is the body of the E2E create-flow article.`; Tags: `e2e`, `create` |

**Steps**
1. Log in as the author at http://localhost:3000/login, confirm the logged-in header affordances appear.
2. Navigate to http://localhost:3000/editor.
3. Enter the Title, Description, Body and add the two Tags from Test data into the corresponding fields.
4. Submit the editor form (click the Publish Article / submit button).
5. Wait for the page to respond and any navigation to settle.

**Expected result**
- The article is created (a POST to `/api/articles` returns 2xx — verifiable in DevTools -> Network).
- The browser is redirected to the article view page for the new article (URL matches
  `/article/<slug>`). TO CONFIRM: exact article-view route path with the dev/BA (assumed `/article/<slug>`).
- The article view shows the Title, Body (rendered), the author (the logged-in user), and the two tags.

**Pass/Fail criteria**: PASS if the article is created and the browser lands on the new article's
view page without a manual second step. Staying on `/editor`, an error, or no redirect is a FAIL.
**Cleanup**: Delete the created article (via the editor Delete action, TC-E2E-06, or from PostgreSQL) so the case can be re-run.

---

### TC-E2E-02 — Newly created article appears in the global feed and the author's profile

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-22, REQ-F-23 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | SUT running; the article from TC-E2E-01 has just been created; logged in as its author |
| **Test data** | Article title: `E2E Create Flow Article`; author username: `e2e_author` (adjust to the seeded author's actual username) |

**Steps**
1. With the article created (TC-E2E-01), navigate to the home page http://localhost:3000/.
2. Select the Global Feed tab if not already active.
3. Locate the created article in the global feed list (search visually / paginate if needed).
4. Navigate to http://localhost:3000/profile/e2e_author.
5. On the profile page, ensure the "My Articles" tab is selected.

**Expected result**
- The created article title is present in the Global Feed list on the home page.
- The created article title is present under the author's profile "My Articles" tab.
- Clicking the article in either location opens its `/article/<slug>` view.

**Pass/Fail criteria**: PASS if the article is visible in BOTH the global feed AND the author's
profile My Articles tab. Missing from either location is a FAIL.
**Cleanup**: Delete the created article (TC-E2E-06 or PostgreSQL).

---

### TC-E2E-03 — Creating an article with an empty title is rejected (validation)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-3 / REQ-F-22 |
| **Type** | E2E (negative/boundary) |
| **Priority** | P1 |
| **Preconditions** | SUT running; logged in as the author; on http://localhost:3000/editor |
| **Test data** | Title: (leave EMPTY); Description: `Body-only, no title`; Body: `Some body text`; Tags: (none) |

**Steps**
1. Navigate to http://localhost:3000/editor while logged in.
2. Leave the Title field empty; fill Description and Body per Test data.
3. Submit the editor form.

**Expected result**
- The article is NOT created — either client-side validation blocks submission or the API returns a
  422/4xx and a visible, human-readable error message is shown (e.g. "title can't be blank").
- The browser stays on `/editor`; no redirect to an article view occurs; no new article appears in
  the global feed. TO CONFIRM: exact validation UX (inline field error vs. list of errors) with the dev/BA.

**Pass/Fail criteria**: PASS if submission is rejected with a visible error and no article is
created. Silent success, a blank page, or an unhandled crash is a FAIL.
**Cleanup**: None (no article created). If one was created in error, delete it.

---

### TC-E2E-04 — Edit an existing article: form pre-fills and changes persist

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-4 / REQ-F-22 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | SUT running; logged in as the author; an article authored by this account already exists (create one via TC-E2E-01) with a known slug |
| **Test data** | Existing article slug: `<slug-of-author-article>`. New Title: `E2E Edited Title`; appended Body text: `\n\nEdited paragraph appended by E2E.` |

**Steps**
1. Log in as the article's author.
2. Navigate to http://localhost:3000/editor/`<slug-of-author-article>`.
3. Observe the form fields on load (before making changes).
4. Change the Title to the new value and append the new Body text per Test data.
5. Submit the editor form.
6. After the update settles, navigate to the article's view page and then re-open `/editor/<new-slug>` if the slug changed. TO CONFIRM: whether editing the title changes the slug, with the dev/BA.

**Expected result**
- On load, the form is **pre-filled** with the article's current Title, Description, Body and Tags
  (not blank).
- The update is accepted (a PUT to `/api/articles/<slug>` returns 2xx — verifiable in DevTools -> Network).
- After saving, the article view page shows the new Title and the appended Body text.
- Re-opening the editor for the article shows the persisted, updated values.

**Pass/Fail criteria**: PASS if the form pre-fills with current values AND the edits persist across
navigation/reload. A blank form on load, or edits not persisting, is a FAIL.
**Cleanup**: Delete the article or restore its original title/body.

---

### TC-E2E-05 — Editing an article the user does not own is denied

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-4 / REQ-F-22 |
| **Type** | E2E (negative) |
| **Priority** | P1 |
| **Preconditions** | SUT running; logged in as the "second user" account; an article authored by a DIFFERENT user exists with a known slug |
| **Test data** | Second-user login — Email: `e2e_second@example.com`, Password: `Passw0rd!123`. Foreign article slug: `<slug-of-article-owned-by-author-account>` |

**Steps**
1. Log in as the second user (NOT the article's author).
2. Manually navigate to http://localhost:3000/editor/`<foreign-article-slug>`.
3. If a form loads, attempt to change the Title/Body and submit.

**Expected result**
- The second user cannot edit the foreign article: either the editor page does not render an
  editable/pre-filled form for a non-owned article (redirect, empty, or not-found/forbidden state),
  or any submitted update is rejected by the API (403/401/422) with the article unchanged.
- After the attempt, the original article (viewed as its owner) is unchanged.
  TO CONFIRM: exact denial UX for a non-owner reaching `/editor/[slug]` (redirect vs. forbidden message) with the dev/BA.

**Pass/Fail criteria**: PASS if a non-owner cannot persist any change to the article. Any accepted
edit by a non-owner is a FAIL (raise a security defect).
**Cleanup**: None (article should be unchanged). If it changed, restore it.

---

### TC-E2E-06 — Delete an article from the editor removes it from all feeds and the author's profile

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-F-22, REQ-F-23 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | SUT running; logged in as the author; an article authored by this account exists and is visible in the global feed and the author's profile (verify via TC-E2E-02 first) |
| **Test data** | Deletable article slug: `<slug-of-author-article>`; author username: `e2e_author` |

**Steps**
1. Log in as the author and open the article's view page or its editor at http://localhost:3000/editor/`<slug>`.
2. Trigger the Delete Article action and confirm any deletion prompt. TO CONFIRM: exact location of the Delete control (article view vs. editor) with the dev/BA — story text says "from the editor".
3. After deletion settles, navigate to the home page http://localhost:3000/ (Global Feed tab).
4. Navigate to http://localhost:3000/profile/e2e_author (My Articles tab).
5. Attempt to open the deleted article directly at http://localhost:3000/article/`<slug>`.

**Expected result**
- The delete is accepted (a DELETE to `/api/articles/<slug>` returns 2xx — verifiable in DevTools -> Network).
- The article no longer appears in the Global Feed.
- The article no longer appears under the author's profile My Articles tab.
- Opening the article's old URL directly shows a not-found / empty state, not the deleted content.

**Pass/Fail criteria**: PASS if the article is gone from the global feed AND the author's profile AND
its direct URL. Remaining in any of these is a FAIL.
**Cleanup**: None (article intentionally deleted). Re-seed if other cases need it.

---

### TC-E2E-07 — Deleting an article that is not owned is not possible

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-F-22 |
| **Type** | E2E (negative) |
| **Priority** | P1 |
| **Preconditions** | SUT running; logged in as the second user; an article authored by a different user exists |
| **Test data** | Second-user login — Email: `e2e_second@example.com`, Password: `Passw0rd!123`. Foreign article slug: `<slug-of-article-owned-by-author-account>` |

**Steps**
1. Log in as the second user.
2. Open the foreign article's view page and its editor URL http://localhost:3000/editor/`<foreign-slug>`.
3. Look for a Delete control; if present, attempt to trigger it.

**Expected result**
- No usable Delete control is available to a non-owner, OR any delete attempt is rejected by the API
  (403/401) and the article remains present in the global feed and its owner's profile.

**Pass/Fail criteria**: PASS if a non-owner cannot delete the article. Any successful deletion by a
non-owner is a FAIL (raise a security defect).
**Cleanup**: Confirm the article still exists; re-create if it was wrongly deleted.

---

### TC-E2E-08 — View own profile: My Articles and Favorited tabs; no follow button for self

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-23 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | SUT running; logged in as the author; the author has ≥1 authored article and has favorited ≥1 article authored by someone else |
| **Test data** | Author username: `e2e_author`; a favorited article title authored by another user: `<known-favorited-article-title>` |

**Steps**
1. Log in as the author.
2. Navigate to http://localhost:3000/profile/e2e_author.
3. Observe the default tab and the list of articles shown.
4. Switch to the "Favorited Articles" tab.
5. Observe whether a Follow/Unfollow control is shown for the author viewing their own profile.

**Expected result**
- The profile shows the author's username/bio/image and a tabbed interface with "My Articles" and
  "Favorited Articles".
- "My Articles" lists the author's own authored articles.
- "Favorited Articles" lists articles the author has favorited (authored by others), not their own
  authored set.
- No Follow/Unfollow button is offered for the user's own profile (typically an "Edit Profile
  Settings" affordance instead). TO CONFIRM: exact self-profile affordance with the dev/BA.

**Pass/Fail criteria**: PASS if both tabs show the correct respective lists and no self-follow
control appears. Wrong list under a tab, or a self-follow button, is a FAIL.
**Cleanup**: None.

---

### TC-E2E-09 — View another user's profile and follow, then unfollow

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-23 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | SUT running; logged in as the author; a different user exists whom the author does NOT currently follow |
| **Test data** | Target username: `e2e_second`; author (viewer) logged in as `e2e_author` |

**Steps**
1. Log in as the author.
2. Navigate to http://localhost:3000/profile/e2e_second.
3. Confirm the Follow control shows an unfollowed state (e.g. "Follow e2e_second").
4. Click the Follow control; wait for it to settle.
5. Reload the page and observe the control's state.
6. Click the control again to Unfollow; wait, then reload.

**Expected result**
- The profile of the other user is shown with a Follow/Unfollow control and their My Articles /
  Favorited tabs.
- After Follow, the control reflects a followed state (e.g. "Unfollow e2e_second") and this survives
  a reload (a POST to `/api/profiles/e2e_second/follow` returns 2xx — verifiable in DevTools -> Network).
- After Unfollow, the control returns to the unfollowed state and this survives a reload (a DELETE to
  the follow endpoint returns 2xx).

**Pass/Fail criteria**: PASS if follow and unfollow both take effect and persist across reload. A
control that does not change state, or does not persist, is a FAIL.
**Cleanup**: Ensure the follow relationship is left in its original (unfollowed) state.

---

### TC-E2E-10 — Unauthenticated visit to /editor redirects to login

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-22 |
| **Type** | E2E (negative) |
| **Priority** | P1 |
| **Preconditions** | SUT running; browser with a fresh profile / cleared cookies (logged OUT) |
| **Test data** | None |

**Steps**
1. In a logged-out browser, navigate directly to http://localhost:3000/editor.
2. Observe the resulting page/URL.
3. Repeat for http://localhost:3000/editor/some-existing-slug.

**Expected result**
- An unauthenticated user cannot reach the editor: the browser is redirected to the login page
  (`/login`) or is otherwise blocked from an editable form. TO CONFIRM: exact redirect target and
  whether a `?redirect=` return param is set, with the dev/BA.

**Pass/Fail criteria**: PASS if a logged-out user cannot use the editor and is sent to login. An
editable, submittable editor form for a logged-out user is a FAIL.
**Cleanup**: None.

---

### TC-E2E-11 — Profile of a nonexistent username shows a not-found state

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-23 |
| **Type** | E2E (negative/boundary) |
| **Priority** | P2 |
| **Preconditions** | SUT running; the username below does not exist in the database |
| **Test data** | Nonexistent username: `no_such_user_zzz_999` |

**Steps**
1. Navigate to http://localhost:3000/profile/no_such_user_zzz_999 (logged in or out — try both).
2. Observe the resulting page.

**Expected result**
- The page shows a graceful not-found / empty state (Next.js not-found or an equivalent message),
  not a raw server error or an unhandled crash. TO CONFIRM: exact not-found UX (Next.js `notFound()`
  vs. custom message) with the dev/BA.

**Pass/Fail criteria**: PASS if a nonexistent profile is handled gracefully (not-found/empty). A 500,
stack trace, or broken page is a FAIL.
**Cleanup**: None.

---

### TC-E2E-12 — Edited article stays consistent across the global feed and profile

| Field | Value |
|-------|-------|
| **Traces to** | AC-3, AC-4 / REQ-F-22, REQ-F-23 |
| **Type** | E2E |
| **Priority** | P2 |
| **Preconditions** | SUT running; logged in as the author; an owned article exists and is visible in the global feed and profile |
| **Test data** | Article slug: `<slug-of-author-article>`; New Title: `E2E Consistency Edited Title` |

**Steps**
1. Edit the owned article's title per TC-E2E-04 and save.
2. Navigate to the home page Global Feed and locate the article.
3. Navigate to the author's profile My Articles tab and locate the article.

**Expected result**
- The updated title is reflected consistently in the article view, the global feed listing, and the
  author's profile listing (allowing for any documented caching/revalidation delay — reload once if needed).
  TO CONFIRM: expected revalidation behaviour (Next.js cache revalidation on edit) with the dev/BA.

**Pass/Fail criteria**: PASS if the edited title appears consistently in all three surfaces after a
reload. A stale title persisting indefinitely in feed/profile is a FAIL.
**Cleanup**: Restore the original title or delete the article.
