# CR-1 — Requirements delta

Epic branch: cr-test/epic-nextjs-migration @ 9c71d78 · Written: 2026-09-28T09:07:26Z · AIRE v1.0
Anchor method: REQ-ID (CR3) — matched on the stable ID, never on line number or position.

---

## Summary

| Class | Count | REQ-IDs |
|---|---|---|
| AMENDED | 1 | REQ-F-17 |
| ADDED | 0 | (none) |
| SUPERSEDED | 0 | (none) |
| UNCHANGED | 44 | all others, byte-identical |

Anchor resolution: resolved 1 / unresolved 0.

---

## REQ-F-17 — AMENDED → @v2

**Location**: `spec/plans/requirements.md:44` (Backend API Route Handlers section)

### Before (v1)

> Fix the N+1 query pattern: replace the per-article `appendFollowers`/`appendFavorites`/`appendTagList`
> loop calls with Sequelize `include` eager loading in the Route Handlers that list/feed articles.

### After (@v2)

> Fix the N+1 query pattern: replace the per-article `appendFollowers`/`appendFavorites`/`appendTagList`
> loop calls in the Route Handlers that list/feed articles with a read path whose query count per request
> is bounded and constant with respect to the number of articles returned. Either Sequelize `include`
> eager loading or a single denormalised read model satisfies this; the mechanism is not constrained.

### What differs

The v1 text named one mechanism — Sequelize `include` eager loading — as the way to fix the N+1 pattern.
The @v2 text states the property the fix must have (a bounded, article-count-independent query count) and
names both `include` and a denormalised read model as satisfying it. The defect being fixed, and the
outcome required, are the same in both revisions.

### Stories re-pointed

| Story | `Covers` before | `Covers` after | Status |
|---|---|---|---|
| 1.4 | `REQ-F-12 (article CRUD + feed slice), REQ-F-14, REQ-F-17, REQ-NF-02, REQ-NF-04` | `… REQ-F-17@v2 …` | re-pointed (CR5) |
| 1.10 (CR-born) | — | `REQ-F-17@v2, REQ-NF-02` | created by this CR |

Stale traces after this CR: 0. No covering story names REQ-F-17 at a version older than @v2.

---

## REQ-NF-02 — UNCHANGED

**Location**: `spec/plans/requirements.md:70`

> Article list/feed responses must not exhibit N+1 query behavior — verified via Sequelize query logging
> showing a bounded number of queries per feed request, independent of article count.

Byte-identical (RV-5). It constrains the outcome, not the mechanism, and REQ-F-17@v2 preserves that
outcome. No version is minted.

---

## RV predicate results

| Rule | Result |
|---|---|
| RV-1 — amendment mints `@v<N+1>` | REQ-F-17: (unversioned = v1) → @v2 — PASS |
| RV-2 — prior text retained, struck through, annotated | applied at `requirements.md:44` — PASS |
| RV-3 — ADDED never mints `@v1` | 0 ADDED — PASS (vacuous) |
| RV-4 — SUPERSEDED retained and marked, never deleted | 0 SUPERSEDED — PASS (vacuous) |
| RV-5 — UNCHANGED byte-identical | 44 unchanged, no diff — PASS |
| RV-6 — IDs never renumbered or reused | no ID renumbered; 1.10 is a story number, not a REQ-ID — PASS |
| RV-7 — stories trace to the version they implement | 1.4 and 1.10 both name REQ-F-17@v2 — PASS |
