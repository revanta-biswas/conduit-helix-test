Feature: Conduit end-to-end journeys (epic scope)
  Cross-story journeys that belong to no single story — the full migrated backend exercised
  end to end. Run by the B3 tier on the last work unit of the cycle only.

  # @REQ tags map each journey to the requirements it spans.

  @REQ-F-10 @REQ-F-11 @REQ-F-12
  Scenario: A new user registers, writes an article, and it appears in the global feed
    Given a fresh Conduit system
    When a new user "alice" registers and logs in
    And "alice" publishes an article "Hello Conduit" tagged "intro"
    Then the global feed contains "Hello Conduit" by "alice"
    And the tag list includes "intro"

  @REQ-F-12 @REQ-F-13
  Scenario: A reader follows an author, favorites their article, and comments on it
    Given a fresh Conduit system
    And an author "bob" with a published article "Deep Dive"
    When a new user "carol" registers and logs in
    And "carol" starts following "bob"
    And "carol" adds the article "deep-dive" to favorites
    And "carol" leaves the comment "great read" on the article "deep-dive"
    Then "carol"'s personal feed contains "Deep Dive"
    And the article "deep-dive" has 1 favorite and 1 comment
    And the profile of "bob" as seen by "carol" shows following true

  @REQ-F-12
  Scenario: An author edits and then deletes their own article end to end
    Given a fresh Conduit system
    And an author "dave" with a published article "Draft Post"
    When "dave" revises the article "draft-post" body to "final content"
    Then the article "draft-post" body is "final content"
    When "dave" removes the article "draft-post"
    Then the global feed no longer contains "draft-post"

  @REQ-NF-01 @REQ-F-15
  Scenario: A session established at login resolves the current user across requests
    Given a fresh Conduit system
    When a new user "erin" registers and logs in
    Then the session token for "erin" resolves to the current user "erin"
