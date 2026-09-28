# Security Baseline Review — Story 1.4 (2026-09-09)
Scope: articles/tags services + handlers. Result: no Critical/High on changed surface.
- Access control (SECURITY-06): update/delete author-only (403); create/feed require session.
- Injection (SECURITY): Sequelize builder, parameterised where-clauses for author/tag/favorited filters.
- Error handling: mapped Conduit envelope, no leak.
- N+1 fix is a performance/correctness improvement, no security regression.
SEC-ISS routed: NONE.
