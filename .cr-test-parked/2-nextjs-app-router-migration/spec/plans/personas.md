# Personas: conduit-helix-test Next.js Migration

## Solo Developer
**Who**: The single person building, testing, and validating this entire migration — developer, architect, QA, and DevOps all in one, per the Migration Strategy's explicit constraint.
**Motivation**: Wants a unified, modern codebase with less operational overhead (one `npm run dev`, one deployment target) and the known technical debt (N+1 queries, unsafe schema sync, XSS-prone auth storage) fixed along the way, without introducing new risk (hence: no TypeScript, no Tailwind, no Prisma — minimize simultaneous changes).
**Relevant stories**: All (1.1–1.9) — every story is implemented, reviewed, and validated by this persona.

## End User / Reader
**Who**: A visitor or registered user of the Conduit blogging platform — browses articles, follows authors, favorites articles, manages their own profile/settings.
**Motivation**: Wants the same experience as today (nothing should look or feel different) but faster (SSR) and without unexpected logouts (session should persist reliably across navigation/refresh).
**Relevant stories**: 1.2 (register/login/logout), 1.3 (profile viewing, follow/unfollow), 1.4 (browsing articles/feed, tags), 1.5 (favoriting, reading comments), 1.6 (auth pages, settings), 1.7 (home feed, article view).

## Author
**Who**: A registered user who writes and manages their own articles and comments.
**Motivation**: Wants to create, edit, and delete their own articles reliably, with the editor behaving the same as before, and wants their content correctly reflected in feeds and their own profile.
**Relevant stories**: 1.4 (article CRUD API), 1.5 (comments API), 1.8 (article editor page, profile page showing their own articles).
