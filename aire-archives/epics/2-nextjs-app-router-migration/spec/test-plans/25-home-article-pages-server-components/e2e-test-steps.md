# E2E Test Steps — #25 Home & Article Pages (Server Components)

**Purpose**: Verify the complete, user-visible journeys the story delivers end to end — landing on
the home feed, switching between global / personal / tag feeds via URL navigation, paginating, and
opening a single article view with its markdown body and comments. Black-box; every case is derived
from acceptance criteria only.

**Scope**: The `/` (home) and `/article/[slug]` pages as Server Components, plus the URL-search-param
navigation that replaces the former client-side FeedContext.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | [PR #35](https://github.com/revanta-biswas/conduit-helix-test/pull/35) |
| Confirm the story is in the build | `git log --oneline \| grep -i "1.7\|#25\|home.*article"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | `http://localhost:3000` |
| Local services that must be up | PostgreSQL (via Sequelize) — reachable with the connection settings the project's build docs specify |
| Test data / accounts to seed | (a) at least one registered user "Alice" who has published ≥ 12 articles across ≥ 2 distinct tags (to force pagination and populate the tag sidebar); (b) a second registered user "Bob" who follows Alice and has favorited one of her articles; (c) at least one article with a rich markdown body (headings, bold, list, code block) and ≥ 2 comments; (d) note one real article slug as `<known-slug>`. TO CONFIRM: exact seed script / fixtures — the project owns seeding; if none exists, create the above manually through the app UI (Story 1.6/1.8 register + publish flows). |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-E2E-01 — Anonymous visitor lands on home, sees global feed + popular tags + pagination

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-20 |
| **Type** | E2E |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT running per **System Under Test**; not logged in (no session cookie — use a fresh/incognito browser window); seed data (a) present |
| **Test data** | None (anonymous) |

**Steps**
1. Open a fresh/incognito browser window.
2. Navigate to `http://localhost:3000/`.
3. Observe the main feed area and the sidebar.
4. Count the number of article preview cards rendered in the feed.

**Expected result**
- The home page loads with HTTP 200 and renders a list of article preview cards (the **global feed** — articles from all authors).
- A **popular tags** sidebar is visible and lists one or more tags.
- A pagination control is visible (page numbers / offsets) because seed user Alice has ≥ 12 articles. TO CONFIRM: exact page size (Conduit default is 10 per page) — confirm with dev/BA.
- The feed toggle shows a "Global Feed" option as active (no "Your Feed" active for anonymous). TO CONFIRM: whether a "Your Feed" tab is shown at all to anonymous users.

**Pass/Fail criteria**: PASS if the global feed, popular-tags sidebar, and a pagination control all render on `/` with HTTP 200 for an anonymous visitor. Any missing element, or an error page, is a FAIL.
**Cleanup**: None (read-only).

---

### TC-E2E-02 — Logged-in user sees personal feed via URL, then switches to global via navigation

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-3 / REQ-F-20, REQ-F-21 |
| **Type** | E2E |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT running; logged in as Bob (who follows Alice); seed data (a)+(b) present |
| **Test data** | Bob's credentials (from Story 1.6 registration) |

**Steps**
1. Log in as Bob through the app's login page.
2. Navigate to `http://localhost:3000/` and click the "Your Feed" / personal feed toggle (or navigate directly to the personal-feed URL, e.g. `http://localhost:3000/?feed=personal`). TO CONFIRM: exact search-param name/value for the personal feed.
3. Note the browser address bar — record the full URL including any query string.
4. Observe which articles appear in the feed.
5. Click the "Global Feed" toggle.
6. Note the browser address bar again and observe the feed.

**Expected result**
- Selecting the personal feed changes the URL to include a search param (e.g. `?feed=personal`) — it is a **navigation**, not a silent client-state flip.
- The personal feed lists only articles by authors Bob follows (Alice's articles), not the full global set.
- Selecting the global feed again changes the URL (param removed or set to global) and the feed re-renders to show all authors' articles.
- Each toggle is reflected in the URL and is bookmarkable/shareable (the URL alone determines the feed shown).

**Pass/Fail criteria**: PASS if switching feeds changes the URL search params AND the rendered feed content matches the selected feed. FAIL if the feed changes without a URL change, or the URL changes without the feed content changing.
**Cleanup**: Log out.

---

### TC-E2E-03 — Filter the feed by a tag via URL, then open an article and read body + comments

| Field | Value |
|-------|-------|
| **Traces to** | AC-2, AC-3 / REQ-F-20, REQ-F-21 |
| **Type** | E2E |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT running; seed data (a)+(c) present; `<known-slug>` recorded; note one tag `<known-tag>` that appears in the popular-tags sidebar |
| **Test data** | `<known-tag>`, `<known-slug>` |

**Steps**
1. Navigate to `http://localhost:3000/`.
2. In the popular-tags sidebar, click `<known-tag>`.
3. Record the browser URL and observe the feed.
4. Confirm the feed now shows only articles carrying `<known-tag>`.
5. Click an article preview that leads to `<known-slug>` (or navigate directly to `http://localhost:3000/article/<known-slug>`).
6. On the article page, observe the rendered body and scroll to the comments section.

**Expected result**
- Clicking the tag updates the URL with a tag search param (e.g. `?tag=<known-tag>`) — it is a navigation.
- The feed re-renders server-side to show only articles tagged `<known-tag>`.
- The article page (`/article/<known-slug>`) renders the single article with its **markdown body correctly formatted** (headings, bold, list and code block render as HTML, not raw markdown characters).
- A **comments list** is rendered below the article showing the seeded comments.

**Pass/Fail criteria**: PASS if tag filtering is URL-driven and shows only matching articles, AND the article page renders formatted markdown plus the comments list. FAIL on raw/unrendered markdown, missing comments, or tag filter not reflected in the URL.
**Cleanup**: None (read-only).

---

### TC-E2E-04 — Open a non-existent article slug: not-found state, not a crash (negative)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-21 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | SUT running |
| **Test data** | Slug `nonexistent-slug-xyz-000` that does not match any seeded article |

**Steps**
1. Navigate to `http://localhost:3000/article/nonexistent-slug-xyz-000`.
2. Observe the page rendered and, if visible, the HTTP status (browser dev-tools Network tab → the document request status).

**Expected result**
- A graceful **not-found** state is shown (Next.js not-found UI or an equivalent "article not found" message).
- The document response status is 404. TO CONFIRM: whether the story requires a literal 404 status or only a not-found UI — confirm with dev/BA.
- No unhandled server error (no 500 page, no stack trace exposed to the visitor).

**Pass/Fail criteria**: PASS if a not-found state is shown with no 500/stack trace. FAIL on a server error, a blank page, or raw exception text.
**Cleanup**: None.

---

### TC-E2E-05 — Deep-link directly to a tag+pagination URL reproduces the exact feed (boundary)

| Field | Value |
|-------|-------|
| **Traces to** | AC-3, AC-5 / REQ-F-20 |
| **Type** | E2E |
| **Priority** | P2 |
| **Preconditions** | SUT running; seed data (a) present (Alice has ≥ 12 articles so page 2 exists) |
| **Test data** | URL `http://localhost:3000/?tag=<known-tag>&offset=10` (adjust offset to the confirmed page size) |

**Steps**
1. Without any prior navigation, paste `http://localhost:3000/?tag=<known-tag>&offset=10` into a fresh browser tab.
2. Observe the feed and the active pagination page indicator.

**Expected result**
- The page renders directly at the second page of the `<known-tag>`-filtered feed — the URL alone reconstructs the full feed state (feed filter + pagination offset).
- No client-only state is required to reach this view (it works on a cold load / hard refresh).

**Pass/Fail criteria**: PASS if the deep-linked URL renders the correct filtered + paginated feed on a cold load. FAIL if the offset or tag is ignored on direct navigation.
**Cleanup**: None.
