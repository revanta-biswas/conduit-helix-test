# Functional Design — Next.js Modernization

This migration preserves existing business behavior (REQ-NF-01 API parity, REQ-NF-02 no data
migration) — the domain model and business rules below are **inherited from the current system**
(per `spec/plans/atlas-deep-dive.md` and the existing Sequelize models/controllers), not redesigned.
New decisions this migration introduces are called out explicitly.

**New decisions** (from `spec/spec-generation/functional-design-generation.md`):
1. Session cookie: 7-day expiration.
2. Missing-resource pages use Next.js `notFound()`.
3. Feed pagination default stays `limit=3`, unchanged.

---

## 1. Domain Model

```
User
  id, username, email, password (hashed), bio, image
  hasMany Article (as author)
  hasMany Comment (as author)
  belongsToMany User as "Following" (through Follow: followerId, followingId)
  belongsToMany Article as "Favorites" (through Favorite: userId, articleId)

Article
  id, slug, title, description, body, createdAt, updatedAt
  belongsTo User (as author)
  hasMany Comment
  belongsToMany Tag (through ArticleTag)
  belongsToMany User as "FavoritedBy" (through Favorite)

Comment
  id, body, createdAt, updatedAt
  belongsTo User (as author)
  belongsTo Article

Tag
  id, name (unique)
  belongsToMany Article (through ArticleTag)
```

Entity relationships are inherited verbatim from the existing 4 Sequelize models (Story 2 ports
them as-is) — no new entities, no schema change (REQ-NF-02).

## 2. Business Rules (inherited, restated for traceability)

### User / Auth (Story 3, 4)
- Username and email must be unique (existing DB constraints, unchanged).
- Password is hashed with bcrypt before storage (existing behavior, unchanged — SECURITY-16 already satisfied by bcrypt as an adaptive algorithm).
- **NEW**: session cookie (JWT) carries a 7-day expiration; the session is invalid after expiry and the user must re-authenticate (Question 1, Story 3 AC-1/AC-2).
- A user may only update their own profile (`PUT /api/user` always targets the authenticated user — no `userId` parameter accepted from the client).

### Article (Story 5, 5a)
- Slug is derived from the title at creation time; uniqueness enforced (existing behavior).
- Only the article's author may update or delete it (existing authorization rule, restated as Story 5 AC-2).
- Feed queries (global/personal/tag/author) default to `limit=3` (Question 3 — unchanged from current behavior); `offset` supported for pagination.
- **NEW technical constraint, not a behavior change**: feed queries MUST use `include` eager loading for followers/favorites/tagList — Story 5a AC-2, REQ-NF-07. This changes the query plan, not the returned data shape.

### Favorites & Comments (Story 6)
- A user may favorite an article at most once (existing unique-constraint behavior on the join table).
- Only a comment's author may delete it (existing authorization rule, restated as Story 6 AC-3).

### Profiles & Follow (Story 7)
- A user may follow another user at most once (existing unique-constraint behavior).
- A user cannot follow themselves (existing validation, unchanged).
- Profile responses include a `following` boolean computed relative to the requesting viewer (existing behavior).

### Tags (Story 7)
- Tag list is the distinct set of all tags ever used across articles (existing behavior, read-only).

## 3. Data Flow — 3 Highest-Complexity Flows

### 3.1 Article feed (N+1 fix)
```
Request (Server Component direct call OR Route Handler fetch)
  -> articleService.listFeed({ type, filter, viewerId, limit=3, offset })
    -> Article.findAll({
         include: [
           { model: User, as: 'author' },
           { model: Tag },
           { model: User, as: 'favoritedBy', where: viewerId ? {id: viewerId} : undefined, required: false },
           { model: User, as: 'author', include: [{ model: User, as: 'followers', where: {id: viewerId}, required: false }] }
         ],
         limit, offset, order: [['createdAt', 'DESC']]
       })
    -> map to RealWorld article JSON shape (favorited/favoritesCount/author.following computed from the eager-loaded includes, not a per-row query)
  <- { articles: [...], articlesCount }
```
At most 2-3 queries total (the main `findAll` plus its `include` joins), never 3N+1 — verified by query logging per Story 5a AC-2.

### 3.2 Auth (cookie session)
```
POST /api/users/login { email, password }
  -> userService.login({ email, password })
    -> User.findOne({ where: { email } })
    -> bcrypt.compare(password, user.password)
    -> lib/auth.js signSession(user.id) -> jwt (7-day expiry)
  -> lib/auth.js setSessionCookie(response, jwt)  [httpOnly, Secure, SameSite=Strict, maxAge=7d]
  <- 200 { user: { ...profile, token: omitted from body per httpOnly cookie design } }

Subsequent request to a protected route
  -> middleware.ts reads session cookie -> lib/auth.js verifySession(token)
     -> valid: attach userId to request context, proceed
     -> invalid/expired/missing: 401 (Route Handler) or redirect to /login (protected page)
```

### 3.3 Comment / favorite toggle
```
POST /api/articles/:slug/favorite  (authenticated)
  -> favoriteService.favoriteArticle(slug, userId)
    -> Article.findOne({ where: { slug } }) -> 404 via notFound() / errors.js if absent
    -> Favorite.findOrCreate({ where: { userId, articleId } })  [idempotent - existing behavior]
  <- 200 { article: { ...updated favorited: true, favoritesCount } }

DELETE /api/articles/:slug/favorite  (authenticated)
  -> favoriteService.unfavoriteArticle(slug, userId)
    -> Favorite.destroy({ where: { userId, articleId } })
  <- 200 { article: { ...updated favorited: false, favoritesCount } }

POST /api/articles/:slug/comments  (authenticated)
  -> commentService.addComment(slug, authorId, body)
    -> Comment.create({ body, authorId, articleId })
  <- 200 { comment: {...} }

DELETE /api/articles/:slug/comments/:id  (authenticated)
  -> commentService.deleteComment(slug, commentId, requesterId)
    -> Comment.findByPk(commentId) -> ForbiddenError via errors.js if requesterId !== comment.authorId
    -> Comment.destroy(...)
  <- 200 {}
```

## 4. Error Handling (Question 2)

- **Missing resource in a Server Component** (article/profile not found by slug/username): call Next.js `notFound()`, rendering the App Router's `not-found.tsx` with a real 404 status — not an inline "not found" message inside the page.
- **Missing resource in a Route Handler** (Client Component call): `lib/errors.js` `NotFoundError` -> `toErrorResponse` -> `404 { errors: { body: ["<resource> not found"] } }` (RealWorld error shape, matches REQ-NF-01).
- **Validation failure**: `ValidationError` -> `422 { errors: { body: [...] } }`.
- **Auth failure**: `AuthError` -> `401 { errors: { body: ["not authenticated"] } }` from a Route Handler; a redirect to `/login` from `middleware.ts` for a protected page.
- **Authorization failure** (e.g. deleting another user's comment): `ForbiddenError` -> `403 { errors: { body: ["not authorized"] } }`.

## 5. Frontend Component Interaction Flows

- **Home page** (Server Component): fetches feed via direct `articleService.listFeed` call at render time; feed-type/tag/pagination state lives in `searchParams` (Story 13), triggering a fresh Server Component render on navigation — no client-side state management for feed selection.
- **Article view** (Server Component): fetches article + comments via direct service calls; `notFound()` on missing slug.
- **Editor** (Client Component): local form state (title/description/body/tagList), submits via `fetch` to Story 5/6 Route Handlers, redirects to the article view on success.
- **Profile page**: Server Component shell (bio, articles/favorites tabs) with a Client Component "follow button" island that calls the Route Handler and optimistically updates its own local state.
- **Auth pages** (Client Component): local form state, submits via `fetch` to Story 3's Route Handlers; on success, the httpOnly cookie is set by the response and the client redirects — no client-side token storage.
- **Settings page** (Client Component): local form state, submits via `fetch` to Story 4's Route Handler.
