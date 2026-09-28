# Functional Design Plan: Next.js Migration

## Plan Checklist
- [x] Step 1: Read epic-brief.md, requirements.md, stories.md, Story Tracker, application-design.md
- [x] Step 2-4: Plan created (this document), question asked and answered
- [x] Step 5: Answer analyzed (unambiguous — concrete tightened rules chosen below, grounded in the current backend/models/User.js + backend/controllers/users.js, which was read to confirm the actual baseline)
- [ ] Step 6: Generate spec/plans/functional-design.md

## Question & Answer

```
Registration/login validation: match the current backend's exact validation rules, or tighten
them as part of this migration?

[Answer]: Tighten validation now
```

**Grounding**: read `backend/models/User.js` and `backend/controllers/users.js` directly to establish
the actual current baseline (not assumed): registration checks only that `username`, `email`, and
`password` are non-empty; there is no email-format check, no password length/strength check, and no
username-uniqueness check (only email-uniqueness). Login has no rate-limiting or lockout. The tightened
rules below are additive validation on top of this baseline — no existing valid request becomes invalid
under a more permissive rule; some previously-valid-but-weak inputs (e.g. a 3-character password) will
now be rejected.

## Tightened Validation Rules (this migration)

- **Email**: must match a standard email format (`user@domain.tld` shape) in addition to the existing
  uniqueness check. Rejected with `ValidationError("A valid email address is required")`.
- **Password**: minimum 8 characters (current backend has no minimum at all). Rejected with
  `ValidationError("Password must be at least 8 characters")`.
- **Username**: 3-30 characters, alphanumeric plus underscore/hyphen, AND must be unique (current
  backend never checks username uniqueness — two users can currently register the same username,
  which breaks profile URLs `/profile/:username` colliding). Rejected with `ValidationError("Username
  must be 3-30 characters (letters, numbers, _, -)")` or `AlreadyTakenError("Username", "choose
  another")`.
- **Everything else** (bio, image optional fields; login flow's existing `NotFoundError`/wrong-password
  `ValidationError`) carries over unchanged.

This is scoped to Story 1.2 (Auth API) — the story's ACs will be read alongside this design when that
story is implemented via `dev-implement`.
