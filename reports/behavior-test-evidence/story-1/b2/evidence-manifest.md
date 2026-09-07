# Behavioural Test Evidence — B2 (Story 1: Next.js application scaffold)

**Tier**: B2 — every OTHER feature file already in the repo
**Result**: **N/A — the repo genuinely contains no other feature file.**

`spec/behavior/` contains exactly one `.feature` file at this point in the cycle:
`spec/behavior/story-1.feature` — Story 1 is the first story of the epic to be `dev-implement`'d, so
there is no prior-cycle or earlier-work-unit feature file for this story to have broken.

Per `common/behavior-spec.md` Section 6.3: "**N/A**: ... B2 only when no other feature file exists."
This is exactly that case.

## Transparency note on `run.sh`'s literal behaviour

`tests/.evals/behavior/run.sh`'s own `b2` case lists ALL files under `spec/behavior/*.feature`
(`mapfile -t others < <(ls -1 "${BEHAVIOR_DIR}"/*.feature ...)`) without excluding the unit under test
via `AIRE_STORY_KEY` — so with only `story-1.feature` present, invoking `run.sh b2` mechanically
re-runs `story-1.feature` against itself (confirmed: 4/4 scenarios pass, 8.2s, identical to the B1
run). This is harmless here (Story 1 testing itself twice, both green) but is **not** a genuine "every
OTHER feature file" check — there is no other file to check. Recording this tier as a literal PASS
would overstate what was verified; recording it as **N/A** accurately reflects that B2's actual
purpose (catching regressions in earlier work units) cannot yet be exercised, since no earlier work
unit exists. This will become a real, meaningful check starting with Story 2, once `story-2.feature`
exists and B2 for Story 2 genuinely re-verifies `story-1.feature`.
