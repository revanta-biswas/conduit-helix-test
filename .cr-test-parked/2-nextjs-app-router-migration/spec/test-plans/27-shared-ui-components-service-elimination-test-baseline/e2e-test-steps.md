# E2E Test Steps — #27 Shared UI Components, Service Layer Elimination & Test Baseline

**Purpose**: Verify, from the running application only, that every named shared UI component ported
into `src/components/` actually renders and behaves on the pages built in Stories 1.6-1.8 — the
Navbar on every page, the article-preview list, feed toggler, pagination, popular tags, comment
list/editor, favorite/follow buttons, and article-meta/author-info. Black-box; every case is derived
from the acceptance criteria only, never from source code.

**Scope**: The user-visible presence and interaction of the ~20 ported components across the home
feed, article view, editor, auth (login/register), profile, and settings pages. Covers AC-1
(components ported, styling preserved, consumed by pages) with supporting checks for AC-2 (data
reaches components via fetch/Server Actions rather than an Axios path — verified here as an
*observable* end-to-end data flow; the repository-inspection proof lives in
`integration-test-steps.md`).

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | [PR #36](https://github.com/revanta-biswas/conduit-helix-test/pull/36) (plus runtime-fix follow-up [PR #37](https://github.com/revanta-biswas/conduit-helix-test/pull/37)) |
| Confirm the story is in the build | `git log --oneline \| grep -iE "1\.9\|#27\|#36\|#37\|shared.*component\|service.*elimination"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | `http://localhost:3000` |
| Local services that must be up | PostgreSQL (via Sequelize) — reachable with the connection settings the project's build docs specify |
| Test data / accounts to seed | (a) registered user "Alice" who has published >= 12 articles across >= 2 distinct tags (forces pagination + populates the popular-tags sidebar); (b) a second registered user "Bob" who follows Alice and has favorited one of her articles; (c) at least one article by Alice with a markdown body and >= 2 comments — note its slug as `<known-slug>`; (d) known credentials for both accounts. TO CONFIRM: exact seed script / fixtures — the project owns seeding; if none exists, create the above manually through the app UI (register + publish flows). |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-E2E-01 — Navbar renders on every page and reflects auth state

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-26, REQ-F-30 |
| **Type** | E2E |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT running per **System Under Test**; account "Alice" available; a fresh browser window |
| **Test data** | Alice's credentials |

**Steps**
1. In a fresh (logged-out) window, visit each of these URLs in turn: `/`, `/login`, `/register`, `/article/<known-slug>`, `/profile/alice` (TO CONFIRM: exact profile URL shape — `/profile/[username]` observed). For each, observe the top of the page.
2. Confirm a Navbar is present at the top of every page and that its brand link ("conduit") points to `/`.
3. While logged out, confirm the Navbar shows the anonymous links: "Home", "Sign in", "Sign up".
4. Click "Sign in", log in as Alice, then revisit `/` and `/settings`.
5. Confirm the Navbar now shows the authenticated links: "Home", "New Article" (`/editor`), "Settings" (`/settings`), and Alice's username/avatar linking to her profile.
6. Click the brand ("conduit") from any page and confirm it navigates to `/` using client-side Next.js navigation (no full-page reload flash).

**Expected result**
- The Navbar is visible on 100% of the pages visited, in both logged-out and logged-in states.
- Logged-out Navbar shows Home / Sign in / Sign up; logged-in Navbar shows Home / New Article / Settings / profile link.
- All Navbar links resolve to the correct routes (Next.js file-system routes), with no broken link and no React-Router-style hash/redirect behaviour.

**Pass/Fail criteria**: PASS if the Navbar renders on every listed page and correctly switches its link set with auth state, and all links navigate. Any page missing the Navbar, a stale link set, or a broken link is a FAIL.
**Cleanup**: Log out.

---

### TC-E2E-02 — Home feed renders ArticlesPreview list, FeedToggler, PopularTags and ArticlesPagination

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-26 |
| **Type** | E2E |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT running; seed data (a)+(b) present; logged in as Bob (so "Your Feed" is meaningful) |
| **Test data** | Bob's credentials; Alice has >= 12 published articles |

**Steps**
1. Log in as Bob and navigate to `/`.
2. Observe the main feed column and the sidebar.
3. Confirm a list of **ArticlesPreview** cards renders, each showing: author avatar + name (**AuthorInfo/ArticleMeta**), date, article title, description, tag list, and a favorite button (**FavButton**) with a count.
4. Confirm a **FeedToggler** is present offering "Your Feed" and "Global Feed" tabs.
5. Confirm a **PopularTags** sidebar renders one or more clickable tags.
6. Confirm an **ArticlesPagination** control renders (page numbers) because Alice has >= 12 articles. TO CONFIRM: exact page size (Conduit default is 10/page).
7. Click page "2" in the pagination control and observe the feed updating to the next set of previews.

**Expected result**
- ArticlesPreview cards, FeedToggler (Your/Global), PopularTags sidebar, and ArticlesPagination all render on `/`.
- Each preview card shows author, date, title, description, tags and a favorite count — i.e. ArticleMeta/AuthorInfo and FavButton are composed inside the preview.
- Clicking page 2 loads a different set of previews (pagination is functional).

**Pass/Fail criteria**: PASS if all four named components render and pagination changes the visible set. Any of them missing, or pagination not changing the results, is a FAIL.
**Cleanup**: None (read-only).

---

### TC-E2E-03 — FeedToggler switches Global vs. Your Feed and PopularTags filters the feed

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-26, REQ-F-30 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | SUT running; logged in as Bob who follows Alice; seed (a)+(b) present |
| **Test data** | Bob follows Alice; a known tag, e.g. `<known-tag>`, that appears in PopularTags |

**Steps**
1. As Bob on `/`, click the FeedToggler "Your Feed" tab.
2. Observe the feed and note which authors appear.
3. Click "Global Feed" and observe the feed again.
4. In the PopularTags sidebar, click `<known-tag>`.
5. Observe the feed and any new tab/label the toggler shows.

**Expected result**
- "Your Feed" shows only articles by authors Bob follows (i.e. Alice's articles appear; articles by non-followed authors do not).
- "Global Feed" shows articles from all authors (superset of Your Feed).
- Clicking a popular tag filters the feed to articles carrying that tag, and the FeedToggler reflects the active tag selection.
- All switching happens via Next.js navigation / URL search params (no client Axios call, no page crash).

**Pass/Fail criteria**: PASS if Your/Global feeds differ correctly and the tag click filters the feed. FAIL if the toggler does nothing, both feeds are identical, or the tag filter returns unrelated articles.
**Cleanup**: None (read-only).

---

### TC-E2E-04 — Article page renders ArticleMeta, FavButton, FollowButton and CommentList/CommentEditor

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-26 |
| **Type** | E2E |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT running; logged in as Bob; article `<known-slug>` by Alice with >= 2 comments exists |
| **Test data** | `<known-slug>`; Bob (not the author) |

**Steps**
1. As Bob, open `/article/<known-slug>`.
2. Observe the article banner/header and the area below the article body.
3. Confirm **ArticleMeta** renders: author avatar + name (**AuthorInfo**), publish date, and — because Bob is not the author — a **FollowButton** for the author and a **FavButton** (favorite) with a count.
4. Confirm a **CommentList** renders the existing >= 2 comments, each with its author and body.
5. Confirm a **CommentEditor** (comment text area + Post button) renders for the logged-in Bob.
6. Type a comment and click Post; observe the CommentList.
7. Click the FavButton and observe the count; click the FollowButton and observe its label toggling.

**Expected result**
- ArticleMeta (with AuthorInfo), FavButton, FollowButton, CommentList, and CommentEditor all render on the article page.
- Posting a comment adds it to the CommentList without a full-page error.
- FavButton increments/toggles the favorite count; FollowButton toggles between "Follow" and "Unfollow" (or equivalent) label.

**Pass/Fail criteria**: PASS if all named components render and the fav/follow/comment interactions produce their observable effect. FAIL if any component is missing or an interaction throws an error / does nothing.
**Cleanup**: Delete the test comment if the UI allows; unfollow/unfavorite to reset state.

---

### TC-E2E-05 — Author viewing own article sees edit controls, not Follow/Fav (component conditional rendering)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-26 |
| **Type** | E2E |
| **Priority** | P2 (boundary — conditional render of the same ported components) |
| **Preconditions** | SUT running; logged in as Alice (the author); `<known-slug>` is Alice's article |
| **Test data** | Alice's credentials; `<known-slug>` |

**Steps**
1. Log in as Alice and open `/article/<known-slug>` (her own article).
2. Observe the ArticleMeta area.

**Expected result**
- ArticleMeta shows "Edit Article" and "Delete Article" controls for the author.
- The FollowButton / FavButton meant for *other* users' actions are NOT shown against her own author identity (an author does not follow/favorite their own article via these controls). TO CONFIRM: exact author-view control set with dev/BA (Conduit convention: author sees Edit/Delete instead of Follow/Favorite).

**Pass/Fail criteria**: PASS if the author sees edit/delete controls and does not see the other-user Follow/Fav controls against their own article. FAIL if the author sees the follower controls or is missing edit/delete.
**Cleanup**: None (do not actually delete the article).

---

### TC-E2E-06 — Editor page renders and the article editor form works end to end (no Axios path)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-2 / REQ-F-26, REQ-F-27 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | SUT running; logged in as Alice; browser dev-tools Network tab open |
| **Test data** | New article: title "E2E Ported Editor Check", description "check", body "# Body\n\nhello", tags "e2e,ported" |

**Steps**
1. As Alice, open `/editor` (New Article) and confirm the article editor form renders (title, description, markdown body, tags input, Publish).
2. Open the browser Network tab and clear it.
3. Fill the form with the test data and click Publish.
4. Observe the resulting navigation and the created article page.
5. Inspect the Network requests made during publish.

**Expected result**
- The article editor form renders with all fields and a Publish action.
- Publishing creates the article and navigates to its `/article/<slug>` page showing the entered content.
- The publish is served by the app's own Next.js routes / Server Action (same-origin request to the app), NOT by a direct browser call to a separate Axios-driven API client. Observable proxy: no cross-origin XHR to a legacy `/api`-on-another-host and no request bearing an Axios default `User-Agent`/config signature. TO CONFIRM: the exact expected request (Server Action POST vs. same-origin Route Handler) with dev — either is acceptable as long as it is same-origin Next.js, not a client Axios service.

**Pass/Fail criteria**: PASS if the editor renders, publishing works, and the network traffic is same-origin Next.js (Server Action / Route Handler). FAIL if the editor is missing, publish errors, or a client-side Axios-style call to a separate service is observed.
**Cleanup**: Delete the created article via the article page's Delete control.

---

### TC-E2E-07 — Negative: unauthenticated access to interactive components is gated

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-26 |
| **Type** | E2E |
| **Priority** | P2 (negative) |
| **Preconditions** | SUT running; logged OUT (fresh window); `<known-slug>` exists |
| **Test data** | None (anonymous) |

**Steps**
1. In a logged-out window, open `/article/<known-slug>`.
2. Attempt to use the FavButton and FollowButton.
3. Look for the CommentEditor.
4. Directly navigate to `/editor` and `/settings`.

**Expected result**
- The article and its CommentList still render read-only for the anonymous visitor.
- FavButton / FollowButton either prompt to sign in or redirect to `/login` (they do NOT silently succeed for an anonymous user).
- The CommentEditor is hidden or replaced by a "sign in to add comments" prompt for the anonymous visitor. TO CONFIRM: exact anonymous-comment behaviour with dev/BA.
- `/editor` and `/settings` redirect an anonymous user to `/login` (or an equivalent gate).

**Pass/Fail criteria**: PASS if interactive components are gated for anonymous users while read-only content still renders. FAIL if an anonymous user can favorite/follow/comment, or if the read-only article fails to render.
**Cleanup**: None.

---

### TC-E2E-08 — Auth form components render on login/register and the settings form renders (ported forms)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-26 |
| **Type** | E2E |
| **Priority** | P2 |
| **Preconditions** | SUT running |
| **Test data** | For settings: logged in as Alice |

**Steps**
1. Logged out, open `/login`; confirm the login form renders (email + password fields, Sign in button).
2. Open `/register`; confirm the register form renders (username + email + password fields, Sign up button).
3. Submit the login form with blank fields and observe the error-list component.
4. Log in as Alice, open `/settings`; confirm the settings form renders (image URL, username, bio, email, password fields, Update button, and a "log out" control).

**Expected result**
- Login, register, and settings forms all render their expected fields and submit controls.
- Submitting login with blank/invalid fields surfaces a visible error-message list component (the ported error-list / form-errors component), not a silent failure or a raw crash.

**Pass/Fail criteria**: PASS if all three forms render with their fields and the error-list surfaces validation errors. FAIL if any form is missing fields or validation errors are not shown.
**Cleanup**: Do not save settings changes (or revert them).
