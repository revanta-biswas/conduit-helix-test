# Accessibility Test Steps — #25 Home & Article Pages (Server Components)

**Purpose**: Verify the home and article pages meet baseline accessibility expectations — keyboard
navigation, focus visibility, heading structure, link/tag focusability, image alternative text,
colour contrast, and reflow at 200% zoom. Each case references the relevant WCAG 2.1 Success
Criterion. Black-box; derived from the fact that this story delivers user-facing UI pages.

**Scope**: `/` (home) and `/article/[slug]`.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | [PR #35](https://github.com/revanta-biswas/conduit-helix-test/pull/35) |
| Confirm the story is in the build | `git log --oneline \| grep -i "1.7\|#25\|home.*article"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | `http://localhost:3000` |
| Local services that must be up | PostgreSQL (via Sequelize) |
| Test data / accounts to seed | Home feed with ≥ 1 article and ≥ 1 tag in the sidebar; one article `<known-slug>` with markdown body (incl. an image if possible) + ≥ 2 comments. Tools: keyboard only, a screen reader (VoiceOver on macOS / NVDA on Windows), and a contrast checker (browser dev-tools or axe DevTools). TO CONFIRM: whether an automated axe scan is expected as part of ve execution. |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-A11Y-01 — Home page: keyboard-only navigation reaches all interactive elements in a sensible order

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-20 |
| **Type** | Accessibility |
| **Priority** | P1 |
| **WCAG** | 2.1.1 Keyboard (A), 2.4.3 Focus Order (A) |
| **Preconditions** | SUT running; `/` shows feed + tag sidebar + feed toggles + pagination |
| **Test data** | None |

**Steps**
1. Navigate to `http://localhost:3000/`.
2. Using only the keyboard (Tab / Shift+Tab / Enter), move through the page from the top.
3. Confirm you can reach: the feed toggle(s), each article preview link, each popular-tag link, and each pagination control.
4. Note the order in which focus moves.

**Expected result**
- Every interactive control (feed toggles, article links, tag links, pagination links) is reachable by keyboard alone.
- Focus order is logical (roughly top-to-bottom, left-to-right; content before/consistent with visual order).
- Activating a link with Enter navigates (updates the URL) as a mouse click would.

**Pass/Fail criteria**: PASS if all controls are keyboard-reachable in a logical order. FAIL if any control is unreachable or the order is confusing/trapping.
**Cleanup**: None.

---

### TC-A11Y-02 — Home page: visible focus indicator on links and tags (negative if missing)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-20 |
| **Type** | Accessibility |
| **Priority** | P1 |
| **WCAG** | 2.4.7 Focus Visible (AA) |
| **Preconditions** | SUT running; `/` loaded |
| **Test data** | None |

**Steps**
1. Navigate to `http://localhost:3000/`.
2. Tab through article links, tag links, feed toggles and pagination controls.
3. At each stop, observe whether a visible focus indicator (outline/ring/style change) is present.

**Expected result**
- Every focusable element shows a clearly visible focus indicator when it receives keyboard focus.

**Pass/Fail criteria**: PASS if a visible focus indicator appears on every focusable element. FAIL if any element receives focus with no visible indication (a WCAG 2.4.7 failure).
**Cleanup**: None.

---

### TC-A11Y-03 — Home page: heading structure is present and hierarchical

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-20 |
| **Type** | Accessibility |
| **Priority** | P2 |
| **WCAG** | 1.3.1 Info and Relationships (A), 2.4.6 Headings and Labels (AA) |
| **Preconditions** | SUT running; `/` loaded |
| **Test data** | None |

**Steps**
1. Navigate to `http://localhost:3000/`.
2. Use a screen reader's headings list, or browser dev-tools/axe, to enumerate headings and their levels.

**Expected result**
- The page has a meaningful heading hierarchy (one primary heading; section headings such as a feed-area heading and a popular-tags heading), with no skipped levels (no jump from h1 to h3 without an h2).
- Headings describe their sections. TO CONFIRM: expected exact heading text/levels — confirm with design.

**Pass/Fail criteria**: PASS if headings are present, hierarchical, and descriptive. FAIL on missing headings or broken hierarchy.
**Cleanup**: None.

---

### TC-A11Y-04 — Article page: markdown body exposes correct semantic structure to a screen reader

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-21 |
| **Type** | Accessibility |
| **Priority** | P1 |
| **WCAG** | 1.3.1 Info and Relationships (A) |
| **Preconditions** | SUT running; `<known-slug>` body contains a heading, a list, and a code block |
| **Test data** | `<known-slug>` |

**Steps**
1. Navigate to `http://localhost:3000/article/<known-slug>`.
2. With a screen reader active, traverse the article body.
3. Confirm markdown headings are announced as headings, list items as list items, and the code block is distinguishable.

**Expected result**
- The rendered markdown produces real semantic HTML (headings, lists, code) that the screen reader announces correctly — not a flat wall of text and not raw markdown characters.

**Pass/Fail criteria**: PASS if body semantics are conveyed to assistive tech. FAIL if structure is lost or raw markdown is read aloud.
**Cleanup**: None.

---

### TC-A11Y-05 — Article page: author avatar / any content image has meaningful or empty alt text

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-21 |
| **Type** | Accessibility |
| **Priority** | P2 |
| **WCAG** | 1.1.1 Non-text Content (A) |
| **Preconditions** | SUT running; `<known-slug>` page shows an author avatar (and a body image if seeded) |
| **Test data** | `<known-slug>` |

**Steps**
1. Navigate to `http://localhost:3000/article/<known-slug>`.
2. Inspect each `<img>` (dev-tools or axe) and note its `alt` attribute.
3. With a screen reader, confirm how each image is announced.

**Expected result**
- Informative images (e.g. a body image) have a meaningful `alt` describing them.
- Purely decorative images (e.g. a generic avatar) have an empty `alt=""` so they are skipped, rather than announcing a filename or URL.
- No image announces a raw file path/URL as its accessible name.

**Pass/Fail criteria**: PASS if every image has an appropriate alt (meaningful or intentionally empty). FAIL if any image is missing alt entirely or announces a filename.
**Cleanup**: None.

---

### TC-A11Y-06 — Both pages: text and link colour contrast meets AA

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-2 / REQ-F-20, REQ-F-21 |
| **Type** | Accessibility |
| **Priority** | P2 |
| **WCAG** | 1.4.3 Contrast (Minimum) (AA) |
| **Preconditions** | SUT running; `/` and `/article/<known-slug>` loaded |
| **Test data** | None |

**Steps**
1. Open `http://localhost:3000/` and run a contrast check (axe DevTools or a contrast picker) on body text, tag pills, feed-toggle labels and links.
2. Repeat on `http://localhost:3000/article/<known-slug>` for body text, comment text, and the favorite/follow control labels.

**Expected result**
- Normal-size text has a contrast ratio ≥ 4.5:1 against its background; large text ≥ 3:1.
- Tag pills and link text meet the same thresholds.

**Pass/Fail criteria**: PASS if all measured text meets the AA ratio. FAIL if any measured text falls below threshold.
**Cleanup**: None.

---

### TC-A11Y-07 — Both pages reflow at 200% zoom with no loss of content or horizontal scroll trap (boundary)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-2 / REQ-F-20, REQ-F-21 |
| **Type** | Accessibility |
| **Priority** | P2 |
| **WCAG** | 1.4.4 Resize Text (AA), 1.4.10 Reflow (AA) |
| **Preconditions** | SUT running; `/` and article page loaded |
| **Test data** | None |

**Steps**
1. Navigate to `http://localhost:3000/`.
2. Set browser zoom to 200% (Cmd/Ctrl and +).
3. Confirm all content (feed, sidebar tags, feed toggles, pagination) remains available and readable, with no content clipped or overlapping.
4. Repeat on `http://localhost:3000/article/<known-slug>` (body + comments).

**Expected result**
- At 200% zoom, all content and controls remain visible and usable; content reflows rather than being cut off, and there is no two-dimensional scrolling requirement for reading a single column of text.

**Pass/Fail criteria**: PASS if both pages remain fully usable and readable at 200% zoom. FAIL on clipped content, overlap, or lost controls.
**Cleanup**: Reset zoom to 100%.
