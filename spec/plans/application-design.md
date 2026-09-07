# Application Design — Next.js Modernization

Decisions from `spec/spec-generation/application-design-generation.md`:
1. Repository/service layer per resource (`lib/services/`)
2. Shared `lib/errors.js` error helper, ported from `customErrors.js`
3. Server Components call the service layer directly (in-process, no HTTP round-trip); Route Handlers exist for Client Components and external API compatibility
4. UI components reorganized by feature under `conduit-next/components/`
5. All shared/cross-cutting code lives under `lib/` (`lib/db/`, `lib/services/`, `lib/auth.js`, `lib/errors.js`, `lib/helpers.js`)

---

## 1. Components

| Component | Type | Responsibility | Covers Stories |
|---|---|---|---|
| `lib/db/models/{Article,User,Tag,Comment}.js` | Data model | Sequelize Active Record models + associations | 2 |
| `lib/db/index.js` | Data layer | Connection singleton, hot-reload-safe | 2 |
| `lib/auth.js` | Cross-cutting | JWT sign/verify, cookie helpers | 3 |
| `lib/errors.js` | Cross-cutting | Ported `customErrors.js` — typed error classes, RealWorld error-shape serialization | 3 |
| `lib/helpers.js` | Cross-cutting | Ported `backend/helper/helpers.js` utility functions | 3 |
| `middleware.ts` | Cross-cutting | Route protection — validates session cookie before protected routes/Route Handlers | 3 |
| `lib/services/userService.js` | Service | User CRUD, auth business logic (register/login/update) | 3, 4 |
| `lib/services/articleService.js` | Service | Article CRUD + feed queries (with `include` eager loading) | 5, 5a |
| `lib/services/favoriteService.js` | Service | Favorite/unfavorite toggle logic | 6 |
| `lib/services/commentService.js` | Service | Comment CRUD | 6 |
| `lib/services/profileService.js` | Service | Profile read, follow/unfollow toggle | 7 |
| `lib/services/tagService.js` | Service | Tag list read | 7 |
| `app/api/users/route.ts` | Route Handler | Register, login | 3 |
| `app/api/user/route.ts` | Route Handler | Get/update current user | 4 |
| `app/api/articles/[...slug]/route.ts` | Route Handler | Article CRUD, feeds, favorites, comments (nested by slug) | 5, 5a, 6 |
| `app/api/profiles/[username]/route.ts` | Route Handler | Profile read, follow/unfollow | 7 |
| `app/api/tags/route.ts` | Route Handler | Tag list | 7 |
| `app/(home)/page.tsx` | Page (Server Component) | Global/personal/tag feed | 8, 13 |
| `app/article/[slug]/page.tsx` | Page (Server Component) | Article view + comments | 8 |
| `app/editor/page.tsx`, `app/editor/[slug]/page.tsx` | Page (Client Component) | Article create/edit form | 9 |
| `app/profile/[username]/page.tsx` | Page (Server Component + Client island) | Profile view, follow button | 10 |
| `app/login/page.tsx`, `app/register/page.tsx` | Page (Client Component) | Auth forms | 11 |
| `app/settings/page.tsx` | Page (Client Component) | Profile settings form | 12 |
| `components/article/*` | UI | Article card, article list, article meta, comment list/form | 8, 9 |
| `components/profile/*` | UI | Profile header, tabs, follow button | 10 |
| `components/auth/*` | UI | Login form, register form, settings form | 11, 12 |
| `components/shared/*` | UI | Layout/header/footer, pagination, tag list, error banner | 8-12 |

## 2. Component Methods (signatures — business rules detailed in Functional Design)

```
lib/services/articleService.js
  createArticle(authorId, { title, description, body, tagList }) -> Article
  getArticleBySlug(slug, viewerId) -> Article | null
  updateArticle(slug, authorId, patch) -> Article
  deleteArticle(slug, authorId) -> void
  listFeed({ type: 'global'|'personal'|'tag'|'author', filter, viewerId, limit, offset }) -> { articles, articlesCount }

lib/services/favoriteService.js
  favoriteArticle(slug, userId) -> Article
  unfavoriteArticle(slug, userId) -> Article

lib/services/commentService.js
  addComment(slug, authorId, body) -> Comment
  listComments(slug, viewerId) -> Comment[]
  deleteComment(slug, commentId, requesterId) -> void

lib/services/profileService.js
  getProfile(username, viewerId) -> Profile | null
  followUser(username, followerId) -> Profile
  unfollowUser(username, followerId) -> Profile

lib/services/tagService.js
  listTags() -> string[]

lib/services/userService.js
  register({ username, email, password }) -> { user, token }
  login({ email, password }) -> { user, token }
  getCurrentUser(userId) -> User
  updateUser(userId, patch) -> User

lib/auth.js
  signSession(userId) -> jwt string
  verifySession(token) -> { userId } | null
  setSessionCookie(response, token) -> void
  clearSessionCookie(response) -> void

lib/errors.js
  class ValidationError, class AuthError, class NotFoundError, class ForbiddenError
  toErrorResponse(err) -> { status, body: { errors: { body: [...] } } }
```

## 3. Services — Orchestration

- **Route Handlers** are thin: parse request -> call the relevant `lib/services/*` function -> map the result/error via `lib/errors.js` -> return `NextResponse.json(...)`.
- **Server Components** import `lib/services/*` directly (in-process call, no HTTP round-trip) — e.g. `app/(home)/page.tsx` calls `articleService.listFeed(...)` directly rather than fetching `/api/articles`.
- **Client Components** call the Route Handlers via `fetch`/Server Actions (they cannot import server-only service modules directly).
- **`middleware.ts`** runs before both Route Handlers and protected pages, resolving the session from the cookie and attaching `userId` to the request context (or redirecting/401'ing if required and absent).
- **`lib/db/index.js`** is the single Sequelize connection every service imports — no service creates its own connection.

## 4. Component Dependencies

```
Story 1 (scaffold)
  -> Story 2 (lib/db/*)
      -> Story 3 (lib/auth.js, lib/errors.js, lib/helpers.js, middleware.ts, app/api/users, app/api/user services)
          -> Story 4 (lib/services/userService.js -> app/api/user)
          -> Story 5 (lib/services/articleService.js -> app/api/articles CRUD)
              -> Story 5a (articleService.listFeed)
              -> Story 6 (favoriteService, commentService)
                  -> Story 9 (editor page -> Story 5/6 Route Handlers via fetch)
          -> Story 7 (profileService, tagService -> app/api/profiles, app/api/tags)
              -> Story 10 (profile page -> profileService direct call + follow button -> Route Handler fetch)
          -> Story 11 (auth pages -> Story 3 Route Handlers via fetch)
      -> Story 12 (settings page -> Story 4 Route Handler via fetch)
  Story 5a + Story 6 + Story 7 -> Story 8 (home/article pages -> articleService/profileService direct calls)
      -> Story 13 (feed filtering re-architecture, same page)
Stories 8-13 -> Story 16 (Playwright E2E)
Stories 9,10,11,12,13,16 -> Story 14 (cutover)
Story 14 -> Story 15 (decommission)
```

This matches `spec/plans/dependency-graph.yml` exactly — Application Design does not introduce any dependency the Dependency Graph stage didn't already infer; it adds the component-level detail of *what* each edge is actually passing (a service import vs a `fetch` call).

## 5. Design References

None registered — no UI prototype, spec document, or reference implementation was named in any input so far. Every component above is built from the requirements/stories' acceptance criteria and the existing codebase's own behavior (via the Atlas deep dive), not from a design reference.
