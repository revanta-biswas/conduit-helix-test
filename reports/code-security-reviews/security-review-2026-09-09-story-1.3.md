# Security Baseline Review — Story 1.3 (2026-09-09)
Scope: user + profiles services + handlers. Result: no Critical/High on changed surface.
- Access control (SECURITY-06): requireSessionUser on GET/PUT /api/user + follow; public profile intentionally anonymous.
- Insecure design (SECURITY): self-follow prevented, idempotent toggle.
- Injection (SECURITY): Sequelize ORM only.
- Error handling: mapped Conduit envelope, no leak.
SEC-ISS routed: NONE.
