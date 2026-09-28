# API & Contract Evidence — Story 1.3
Endpoints: GET/PUT /api/user, GET /api/profiles/:username, POST/DELETE /api/profiles/:username/follow
Result: 12/12 pass. SH-LOOP-2 attempt 0.
| Check | user | profile | follow |
|---|---|---|---|
| Functional/happy | 200 | 200 | 200 |
| Response codes | 200/401 | 200/404 | 200/401/404 |
| Role authz (401 unauth) | ✅ | N/A (public) | ✅ |
| Error envelope | ✅ | ✅ | ✅ |
| Request validation | ✅ | ✅ | ✅ |
| Response contract | ✅ {user} | ✅ {profile} | ✅ {profile} |
