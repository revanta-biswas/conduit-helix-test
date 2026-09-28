# Integration Test Steps — #22 Articles API — CRUD, Feed & Tags

**Purpose**: Verify the boundaries between the Route Handlers, the Sequelize/PostgreSQL datastore,
and the related entities (Article ↔ Tag ↔ Author ↔ Favorite/Follow) behave correctly end-to-end
through the HTTP surface. Focus is on **eager-loaded enrichment** (AC-4) producing correct joined
data and **tag-association persistence** across create/update.

**Scope**: Article + Tag association persistence; author/favorites/following enrichment via Sequelize
`include`; feed/list joins. All observation is black-box (HTTP responses + optional read-back), no
source code.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` (story #22 merged via PR #31) |
| This story's merged PR | https://github.com/revanta-biswas/conduit-helix-test/pull/31 |
| Confirm the story is in the build | `git log --oneline \| grep -i "1.4\|#22\|articles"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | `http://localhost:3000`, API under `/api/` |
| Local services that must be up | PostgreSQL (via Sequelize) |
| Test data / accounts to seed | User A `alice`, User B `bob` (see api-test-steps Common test data) |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-INT-01 — Tags created via article POST persist and appear in GET /api/tags

| Field | Value |
|-------|-------|
| **Traces to** | AC-2, AC-3 / REQ-F-12, REQ-F-14 |
| **Type** | Integration (handler ↔ Tag table) |
| **Priority** | P1 |
| **Preconditions** | User A authenticated; tag `nessie` does not yet exist |
| **Test data** | `$TOKEN_A` |

**Steps**
1. `GET /api/tags` and confirm `nessie` is absent.
2. `POST /api/articles` (auth A) with `tagList: ["nessie","dragons"]`.
3. `GET /api/tags` again.
4. `GET /api/articles/:slug` for the new article.

**Expected result**
- Step 2 succeeds (`200`), returned `tagList` == `["nessie","dragons"]`.
- Step 3: `tags` now includes `nessie` (new tag was created and persisted) and `dragons` is not
  duplicated (existing tag was reused, not re-created).
- Step 4: the article's `tagList` still equals `["nessie","dragons"]` on a fresh read (persisted,
  not just echoed).

**Pass/Fail criteria**: PASS if the new tag is persisted and visible in `/api/tags`, the existing
tag is reused, and the association survives a fresh read. A duplicated tag, a lost association, or a
missing tag is a FAIL.
**Cleanup**: DELETE the created article with `$TOKEN_A`.

---

### TC-INT-02 — Tag re-association on PUT removes old links and adds new (no orphans)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2, AC-3 / REQ-F-12, REQ-F-14 |
| **Type** | Integration (handler ↔ join table) |
| **Priority** | P1 |
| **Preconditions** | An article owned by A with `tagList: ["dragons","training"]` |
| **Test data** | `$TOKEN_A` |

**Steps**
1. `PUT` the article with `tagList: ["dragons","flying"]`.
2. `GET` the article and inspect `tagList`.
3. `GET /api/tags`.
4. `GET /api/articles?tag=training` and `GET /api/articles?tag=flying`.

**Expected result**
- Step 2: `tagList` == `["dragons","flying"]` — `training` link removed, `flying` link added.
- Step 3: `flying` now present in the global tag list.
- Step 4: the article is ABSENT from `?tag=training` and PRESENT in `?tag=flying`.

**Pass/Fail criteria**: PASS if the article's tag associations are fully replaced and filters reflect
the change. Stale `training` association still filtering the article in is a FAIL.
**Cleanup**: DELETE the article with `$TOKEN_A`.

---

### TC-INT-03 — Author enrichment (following flag) is correct per requesting user

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-F-12, REQ-NF-02 |
| **Type** | Integration (Article ↔ Author ↔ Follow join) |
| **Priority** | P1 |
| **Preconditions** | User A follows User B; User B has an article; User C exists and follows nobody |
| **Test data** | `$TOKEN_A`, `$TOKEN_B`; `TO CONFIRM: seed a User C or reuse an unfollowing account` |

**Steps**
1. As A, `GET /api/articles?author=bob` (auth A).
2. As B (article's own author), `GET /api/articles?author=bob` (auth B).
3. As an unauthenticated caller, `GET /api/articles?author=bob`.

**Expected result**
- Step 1: each article's `author.following` == `true` (A follows B).
- Step 2: `author.following` == `false` (B does not follow themselves).
- Step 3: `author.following` == `false` (anonymous).
- In all three the embedded `author` object is fully populated (`username`, `bio`, `image`) from the
  eager-loaded join, not null.

**Pass/Fail criteria**: PASS if `following` is computed per requesting user and the author is fully
joined. A constant/incorrect `following` value or a null author is a FAIL.
**Cleanup**: None.

---

### TC-INT-04 — Favorites enrichment (favorited flag + count) is correct

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-F-12, REQ-NF-02 |
| **Type** | Integration (Article ↔ Favorite join) |
| **Priority** | P1 |
| **Preconditions** | An article by A; User B has favorited it; User A has not |
| **Test data** | `$TOKEN_A`, `$TOKEN_B` |

**Steps**
1. As B, `GET /api/articles/:slug` (auth B).
2. As A, `GET /api/articles/:slug` (auth A).
3. Unauthenticated, `GET /api/articles/:slug`.

**Expected result**
- All three: `favoritesCount` == `1` (one favoriter, B).
- Step 1: `favorited` == `true` (B favorited it).
- Steps 2 and 3: `favorited` == `false` (A hasn't; anonymous can't).

**Pass/Fail criteria**: PASS if `favoritesCount` is a correct aggregate and `favorited` is per-user.
A wrong count or a per-user flag that ignores the caller is a FAIL.
**Cleanup**: None.

---

### TC-INT-05 — Eager-loaded list returns fully-joined objects (no lazy-load holes)

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-F-12, REQ-NF-02 |
| **Type** | Integration (list eager loading) |
| **Priority** | P1 |
| **Preconditions** | DB seeded with ≥10 articles across ≥3 authors, varied tags and favorites |
| **Test data** | `$TOKEN_A` |

**Steps**
1. As A, `GET /api/articles?limit=10` (auth A).
2. For EVERY element in `articles`, verify the nested/derived fields are populated.

**Expected result**
- For every article element: `author` is a full object (never null / never just an id);
  `tagList` is an array (possibly empty, never null); `favorited` is a boolean; `favoritesCount`
  is an integer.
- No element is missing any of these — i.e. the eager `include` populated all associations in the
  single list query, not lazily per row.

**Pass/Fail criteria**: PASS if all elements are fully hydrated. Any null author, null tagList, or
missing derived field on any row is a FAIL (indicates a broken/partial include).
**Cleanup**: None.

---

### TC-INT-06 — Deleting an article cleans up its tag associations (no dangling filter hits)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2, AC-4 / REQ-F-12 |
| **Type** | Integration (cascade / join cleanup) |
| **Priority** | P2 |
| **Preconditions** | An article by A tagged `soloTag` (a tag used by no other article) |
| **Test data** | `$TOKEN_A` |

**Steps**
1. Confirm `GET /api/articles?tag=soloTag` returns the article.
2. `DELETE /api/articles/:slug` (auth A).
3. `GET /api/articles?tag=soloTag` again.
4. `GET /api/tags`.

**Expected result**
- Step 3: the deleted article is absent; `articlesCount` for that tag is `0` (no dangling
  article↔tag link surfaces it).
- Step 4: `TO CONFIRM: whether an orphaned tag (now used by zero articles) should remain in
  /api/tags or be removed — confirm intended behaviour with dev/BA; the RealWorld spec is silent.`
  Record the observed behaviour for parity comparison.
- No 500 at any step.

**Pass/Fail criteria**: PASS if the deleted article no longer surfaces under its tag and no error
occurs. The deleted article still appearing under `?tag=soloTag` is a FAIL.
**Cleanup**: None (delete performed in-test).
