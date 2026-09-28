# CR-1 — index

REQ-F-17 no longer mandates Sequelize `include`; a denormalised read model is permitted.

| File | What it holds |
|---|---|
| `change-request.md` | The 10-section Change Request. Section 4 carries `CR-BUILDS-STORY: 1.10`; Section 5b is the Test Change Authorization list; Section 6 is the code-generation plan `dev-implement` reads. |
| `requirements-delta.md` | REQ-F-17 before/after, the `@v2` transition, re-pointed stories, RV-1…RV-7 results. |
| `impact-ledger.md` | The five walks with a citation on every row, the architecture impact and the impact tags. |

## Parallel-safety notes

- This run was an **integration-branch writer**: it committed on `cr-test/epic-nextjs-migration`
  directly, pulling immediately before and pushing immediately after
  (`common/parallel-work-state.md` Section 6).
- No `runtime-artifacts/stories/…` fragment was created. Story 1.10 gets one under the unit key
  `story-1.10` when `dev-implement` claims it.
- `cr-1` is this bundle's identifier, never a unit key.
- Story 1.10 is left `Ready for Development` and **unclaimed**. `dev-implement`'s own Story Selection
  makes the claim, as it does for every other story.

## What happens next

`dev-implement 1.10` reads Section 6 as its plan and Section 5b as the list of earlier tests it is
authorised to change, writes the code, runs every gate including Test Impact Reconciliation, and raises
the `[STORY]` PR.
