# NFR Design Plan — Next.js Modernization

## Context Analyzed
- `spec/plans/nfr.md` (approved NFR Requirements) — tech stack, security mapping, scale context all fixed.

## Category Evaluation

- **Resilience Patterns**: no retry/circuit-breaker pattern needed — single DB dependency, no external API calls (per `spec/plans/atlas-deep-dive.md` — "no third-party APIs, queues, or cloud services"). Sequelize's built-in connection pool + `lib/errors.js` fail-closed handling (already specified in `nfr.md`) is sufficient. No question needed — evidence-backed N/A.
- **Scalability Patterns**: no scaling mechanism needed at this app's confirmed scale (solo/demo, no formal SLA, no auto-scaling in the migration plan's own scope). No question needed — evidence-backed N/A.
- **Performance Patterns**: the N+1 fix (Sequelize `include` eager loading) and `cache: 'no-store'` policy are already specified in `functional-design.md` / `nfr.md`. One open question below (cache strategy for genuinely static content).
- **Security Patterns**: SECURITY-01 through 16 mapping already done in `nfr.md`. One open question below (secrets management mechanism for Fly.io).
- **Logical Components**: no new infrastructure component (queue, cache, circuit breaker) — confirmed N/A per the Atlas deep dive's "no third-party APIs, queues, or cloud services" finding and REQ-NF-02's DB-retention scope.

## Clarifying Questions

## Question 1
**Performance Pattern** — Should genuinely static content (e.g. the tags list, which changes infrequently) use Next.js's data-cache (`fetch` with revalidation, or `unstable_cache`), or should every data call use `cache: 'no-store'` uniformly for simplicity?

A) Uniform `cache: 'no-store'` everywhere, including tags — simplest mental model, avoids any stale-data risk during/after migration, and the tags list query is cheap enough that caching isn't needed for performance at this scale

B) Cache the tags list with a short revalidation window (e.g. `revalidate: 60`) since it changes infrequently — a small performance optimization

C) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 2
**Security Pattern** — Fly.io deployment needs the `DATABASE_URL` and JWT signing secret as environment variables. Should these be set via `fly secrets set` (Fly.io's secrets mechanism, encrypted at rest) exclusively, or is a `.env` file (gitignored) also acceptable for local/staging use?

A) `fly secrets set` for production; a gitignored `.env.local` for local development only (never committed, never used in production) — matches SECURITY-12's "no hardcoded credentials" rule and is the standard Next.js local-dev pattern

B) A single `.env` approach for all environments, synced manually to Fly.io's env var UI (not the encrypted secrets store)

C) Other (please describe after [Answer]: tag below)

[Answer]: A
