# Accessibility Test Steps — #27 Shared UI Components, Service Layer Elimination & Test Baseline

**Purpose**: Verify the shared UI components this story ports (Navbar, favorite/follow buttons,
feed toggler, pagination, comment editor, auth/settings forms) remain operable and perceivable —
keyboard-only navigation, visible focus, accessible names/labels, colour contrast, error
announcement, and 200% zoom — because they are reused on every page and any accessibility regression
propagates everywhere. Black-box; derived from AC-1 (components ported and consumed by all pages).

**Scope**: WCAG 2.1 AA on the ported shared components as they appear on `/`, `/article/[slug]`,
`/login`, `/register`, `/settings`. No performance target and no new interaction pattern are in
scope (styling is preserved as-is), so this validates *no regression* in the reused components.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | [PR #36](https://github.com/revanta-biswas/conduit-helix-test/pull/36) (plus runtime-fix follow-up [PR #37](https://github.com/revanta-biswas/conduit-helix-test/pull/37)) |
| Confirm the story is in the build | `git log --oneline \| grep -iE "1\.9\|#27\|#36\|#37"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | `http://localhost:3000` |
| Local services that must be up | PostgreSQL (via Sequelize) |
| Test data / accounts to seed | User "Alice" with seeded articles/tags; article `<known-slug>` with comments; Alice's credentials |
| Tester tools | Keyboard only; a screen reader (VoiceOver on macOS / NVDA on Windows); a contrast checker (e.g. browser dev-tools accessibility pane or axe DevTools); browser zoom |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-A11Y-01 — Navbar is fully keyboard operable with visible focus (happy)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-26 (WCAG 2.1.1 Keyboard, 2.4.7 Focus Visible) |
| **Type** | Accessibility |
| **Priority** | P1 |
| **Preconditions** | SUT running; on `/`; mouse not used |
| **Test data** | Logged in as Alice (to expose the full authenticated link set) |

**Steps**
1. Load `/` and press `Tab` from the top of the page.
2. Continue tabbing through the Navbar links (brand, Home, New Article, Settings, profile).
3. Observe the focus indicator on each link.
4. Press `Enter` on a focused Navbar link.

**Expected result**
- Every Navbar link is reachable by `Tab` in a logical left-to-right order.
- Each focused link shows a clearly visible focus indicator (outline/ring), not focus that is invisible or clipped.
- `Enter` activates the focused link and navigates.

**Pass/Fail criteria**: PASS if all Navbar links are keyboard-reachable, show visible focus, and activate with `Enter`. Any unreachable link, missing focus indicator, or dead `Enter` is a FAIL.
**Cleanup**: None.

---

### TC-A11Y-02 — Icon buttons (FavButton, FollowButton) have accessible names (happy)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-26 (WCAG 4.1.2 Name/Role/Value, 1.1.1 Non-text Content) |
| **Type** | Accessibility |
| **Priority** | P1 |
| **Preconditions** | SUT running; logged in as Bob; on `/article/<known-slug>` (Alice's article) |
| **Test data** | `<known-slug>` |

**Steps**
1. Open `/article/<known-slug>` and start a screen reader.
2. Navigate (via screen-reader controls) to the FavButton and the FollowButton.
3. Listen to how each control is announced.
4. Also tab to each with the keyboard and activate with `Enter`/`Space`.

**Expected result**
- FavButton is announced with a meaningful name and its state/count (e.g. "Favorite article, 3" / "Unfavorite"), not just "button".
- FollowButton is announced with the author context (e.g. "Follow Alice" / "Unfollow Alice"), not just "button".
- Both are operable with `Enter`/`Space` and reflect their state change to the screen reader after activation.

**Pass/Fail criteria**: PASS if both buttons have descriptive accessible names and are keyboard-operable with state announced. A button announced only as "button" (no name), or not keyboard-operable, is a FAIL.
**Cleanup**: Revert any favorite/follow toggles made.

---

### TC-A11Y-03 — FeedToggler and ArticlesPagination are keyboard operable with clear current state

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-26 (WCAG 2.1.1 Keyboard, 4.1.2 Name/Role/Value) |
| **Type** | Accessibility |
| **Priority** | P2 |
| **Preconditions** | SUT running; on `/`; seed data forcing pagination present |
| **Test data** | Alice with >= 12 articles |

**Steps**
1. On `/`, tab to the FeedToggler tabs and activate "Global Feed" / "Your Feed" with the keyboard.
2. Tab to the ArticlesPagination control and activate a different page number with the keyboard.
3. With a screen reader, note how the active feed tab and the current page are conveyed.

**Expected result**
- Both FeedToggler tabs and pagination page controls are reachable and activatable by keyboard.
- The active feed tab and the current page are programmatically conveyed (e.g. `aria-current`, "selected"/"current page" announced), not indicated by colour alone.

**Pass/Fail criteria**: PASS if both controls are keyboard-operable and current state is conveyed non-visually. FAIL if either is mouse-only or the active/current state is colour-only.
**Cleanup**: None.

---

### TC-A11Y-04 — Auth/settings form fields have labels and errors are announced (happy + negative)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-26 (WCAG 1.3.1 Info/Relationships, 3.3.1 Error Identification, 3.3.2 Labels) |
| **Type** | Accessibility |
| **Priority** | P1 |
| **Preconditions** | SUT running; on `/login`, then `/register`, then `/settings` (logged in as Alice for settings) |
| **Test data** | Blank / invalid submissions |

**Steps**
1. On `/login`, tab through the fields with a screen reader and confirm each field announces a label (email, password).
2. Submit the login form empty and observe the error-list component.
3. Repeat the label check on `/register` and `/settings`.
4. With the screen reader active, trigger a validation error and note whether the error is announced.

**Expected result**
- Every form field has a programmatically associated label announced by the screen reader (no unlabeled inputs relying on placeholder text alone).
- On invalid submit, the error-list is rendered and the errors are announced / associated with the form (e.g. a live region or focus moved to the error summary). TO CONFIRM: exact error-announcement mechanism with dev.

**Pass/Fail criteria**: PASS if all fields are labeled and validation errors are perceivable to a screen-reader user. An unlabeled field, or an error shown visually but never announced, is a FAIL.
**Cleanup**: Do not save settings changes.

---

### TC-A11Y-05 — Colour contrast and 200% zoom on shared components (negative/boundary)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-26 (WCAG 1.4.3 Contrast Minimum, 1.4.4 Resize Text, 1.4.10 Reflow) |
| **Type** | Accessibility |
| **Priority** | P2 (boundary) |
| **Preconditions** | SUT running; on `/` and `/article/<known-slug>`; contrast checker available |
| **Test data** | The preserved (non-Tailwind) CSS as shipped |

**Steps**
1. Using a contrast checker, sample the Navbar links, the FavButton/FollowButton text, the pagination numbers, and body/preview text against their backgrounds.
2. Record each contrast ratio.
3. Set browser zoom to 200% and re-view `/` and the article page.
4. Observe whether content reflows without horizontal scrolling or clipped/overlapping controls.

**Expected result**
- Normal text meets >= 4.5:1 and large text/UI affordances meet >= 3:1 contrast.
- At 200% zoom the shared components (Navbar, buttons, pagination, forms) remain usable — content reflows, nothing is clipped or requires two-dimensional scrolling for a single column of content.

**Pass/Fail criteria**: PASS if measured contrast meets WCAG AA and 200% zoom keeps components usable. A sampled ratio below the threshold, or components breaking/clipping at 200%, is a FAIL. NOTE: because styling is *preserved as-is* from the legacy stack, a contrast failure may be a pre-existing legacy issue — record it, and raise it as a defect regardless (it now ships in the migrated app). TO CONFIRM with BA whether preserving a legacy contrast failure is acceptable for this migration story.
**Cleanup**: Reset zoom to 100%.
