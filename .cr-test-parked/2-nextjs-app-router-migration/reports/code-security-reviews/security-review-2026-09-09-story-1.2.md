# Security Baseline Review — Story 1.2 (2026-09-09)

**Scope**: diff of story/1.2-auth-api (src/lib/{errors,helpers,auth,services/users}.js, src/app/api/users/**, src/middleware.js).

## Result: ✅ No 🔴 Critical / 🟠 High findings on the changed surface

| Rule | Assessment |
|---|---|
| SECURITY-01 Encryption/secrets | ✅ JWT secret from env (JWT_SECRET ?? JWT_KEY); no hardcoded secret. |
| SECURITY-06 Access control | ✅ requireSessionUser throws UnauthorizedError; register/login intentionally public. |
| SECURITY-09 JWT security | ✅ Token in httpOnly cookie (not localStorage); HS256 default, never 'none'; secret from env. |
| SECURITY-12 Session integrity | ✅ httpOnly + sameSite=lax + secure-in-production cookie; verifySession returns null on tamper. |
| SECURITY-04 Input validation | ✅ Tightened rules (email format, password ≥8, username format+uniqueness) enforced server-side. |
| SECURITY-16 Cryptographic standards | ✅ bcrypt (cost 10) for password hashing — unchanged from legacy. |
| SECURITY-15 Error handling | ✅ Route Handlers map every error to the Conduit envelope; no stack/exception leak to the client. |
| SECURITY-13 Supply chain | ⚪ Advisory: jsonwebtoken@9.0.3, bcryptjs added — 0 new npm-audit vulns. |

## SEC-ISS findings routed to remediation: NONE
