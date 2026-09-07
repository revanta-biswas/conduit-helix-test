# Cycle-level behaviour — Next.js Modernization
#
# Written ONCE per cycle (STOP CHECKPOINT), per common/behavior-spec.md Section 3.
# These are the journeys that span MULTIPLE stories and become testable only once several
# stories exist. They are NOT copies of per-story scenarios (those live in spec/behavior/story-N.M.feature,
# written just before each story's code, during dev-implement). Tagged @REQ-<id> against requirements.md.
#
# This is the contract the B3 tier (common/behavior-spec.md Section 6) runs against, once, on the
# last work unit of this epic (Story 15 — Decommission old stack — or Story 16/14, whichever's PR
# merges last per the live merge-state check at that time).

Feature: Conduit end-to-end journeys on the migrated Next.js stack

  Background:
    Given the conduit-next application is running against the existing PostgreSQL database
    And the database schema and data were not migrated or altered (REQ-NF-02)

  @REQ-F-03 @REQ-F-04 @REQ-F-09 @REQ-F-12
  Scenario: A new user registers, is authenticated via httpOnly cookie, and edits their profile
    Given a visitor is on the "/register" page
    When they register with a unique username, email, and password
    Then a session cookie is set with "HttpOnly", "Secure", and "SameSite" attributes (REQ-NF-03)
    And no JWT is present in any client-readable storage (localStorage/sessionStorage)
    And they are redirected to the home feed as an authenticated user
    When they navigate to "/settings" and update their bio and image URL
    Then "GET /api/user" reflects the updated profile on next load
    And the update was authorized using only their own session — no other user's data was modified

  @REQ-F-05 @REQ-F-05a @REQ-F-06 @REQ-F-09 @REQ-F-10
  Scenario: An author writes an article, another user favorites it, follows the author, and sees it in their personal feed
    Given user "A" is registered and authenticated
    And user "B" is registered and authenticated
    When "A" publishes a new article with a title, description, body, and tag list
    Then the article appears in the global feed with a slug derived from its title
    When "B" opens the article and favorites it
    Then the article's "favoritesCount" increments by 1 and "favorited" is "true" for "B"
    When "B" follows "A" from the article's author byline
    Then "A" appears in "B"'s following list
    And when "B" switches the home feed to "Your Feed" (personal feed, REQ-F-12 URL-search-param re-architecture)
    Then "A"'s article appears in "B"'s personal feed
    And the feed request used eager-loaded includes, not a per-article N+1 query loop (REQ-F-05a / REQ-NF-07)

  @REQ-F-05 @REQ-F-06 @REQ-F-10
  Scenario: A comment thread and tag-filtered browsing across two users
    Given user "A" has published an article tagged "nextjs" and "migration"
    And user "B" is registered and authenticated
    When "B" adds a comment on "A"'s article
    Then the comment appears in the article's comment list attributed to "B"
    When "B" attempts to delete a comment authored by someone else
    Then the request is rejected with 403 (object-level authorization, SECURITY-08)
    When a visitor filters the home feed by the tag "migration"
    Then only articles tagged "migration" are returned, including "A"'s article

  @REQ-F-03 @REQ-NF-03
  Scenario: An unauthenticated request to a protected route is denied, and an expired session is rejected
    Given no session cookie is present
    When a request is made to "PUT /api/user"
    Then the response is 401 and no user data is modified
    Given a session cookie carrying an expired JWT (issued more than 7 days ago)
    When a request is made to a protected page
    Then conduit-next/middleware.ts rejects the session and redirects to "/login"

  @REQ-F-13 @REQ-F-14 @REQ-NF-05
  Scenario: Production cutover to Fly.io preserves all data and behavior, then the old stack is decommissioned
    Given a pg_dump backup was taken immediately before cutover (REQ-NF-05)
    And conduit-next is deployed to Fly.io as the single running process
    When the same user journeys (registration, articles, favorites, follow, comments, feeds) are exercised against the Fly.io deployment
    Then every response shape matches the RealWorld API spec exactly (REQ-NF-01)
    And the same existing PostgreSQL data is visible with no row-count drift
    When the old stack is decommissioned as the final story
    Then "backend/" and "frontend/" no longer exist in the repository
    And the root package.json workspaces reference only "conduit-next/"
    And a rollback path existed at every prior phase and was never required (REQ-NF-05)
