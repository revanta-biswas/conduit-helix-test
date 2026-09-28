Feature: User Profile API — Current User, Public Profiles & Follow
  As an end user
  I want to view and update my own profile, view others' profiles, and follow/unfollow them
  So that I can manage my identity and curate who I follow

  # Story 1.3 — Covers REQ-F-11, REQ-F-13
  # Bound to the public service surface: src/lib/services/{user,profiles}.js.

  @AC-1
  Scenario: The current user can read their own profile
    Given a registered user with email "amy@conduit.io" and username "amy"
    When that user requests the current user
    Then the current user has email "amy@conduit.io" and username "amy"

  @AC-1
  Scenario: The current user can update bio, image, and email
    Given a registered user with email "ben@conduit.io" and username "ben"
    When that user updates their bio to "hello world" and image to "http://img/x.png"
    Then the current user has bio "hello world" and image "http://img/x.png"

  @AC-2
  Scenario: A public profile can be viewed by anyone with a following flag
    Given a registered user with email "cara@conduit.io" and username "cara"
    When an anonymous visitor views the profile of "cara"
    Then the profile has username "cara" and following is false

  @AC-2
  Scenario: Viewing a non-existent profile is not found
    Given no user exists with username "nobody"
    When an anonymous visitor views the profile of "nobody"
    Then the profile request is rejected as not found

  @AC-3
  Scenario: A user can follow another user
    Given a registered user with email "dan@conduit.io" and username "dan"
    And a registered user with email "eve@conduit.io" and username "eve"
    When "dan" follows "eve"
    Then the profile of "eve" as seen by "dan" has following true
    And the follower count of "eve" is 1

  @AC-3
  Scenario: A user can unfollow a user they follow
    Given a registered user with email "finn@conduit.io" and username "finn"
    And a registered user with email "gwen@conduit.io" and username "gwen"
    And "finn" already follows "gwen"
    When "finn" unfollows "gwen"
    Then the profile of "gwen" as seen by "finn" has following false

  @AC-4
  Scenario: Updating the current user requires authentication
    Given no authenticated user
    When an update to the current user is attempted without a session
    Then the request is rejected as unauthorized

  @AC-3
  Scenario: A user cannot follow themselves
    Given a registered user with email "hana@conduit.io" and username "hana"
    When "hana" follows "hana"
    Then the follow is rejected with a validation error
