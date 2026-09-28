Feature: Favorites & Comments API
  As a reader
  I want to favorite/unfavorite articles and read/add/delete comments
  So that I can curate my favorites and participate in article discussions

  # Story 1.5 — Covers REQ-F-12 (favorites + comments slice)
  # Bound to the favorites + comments services public surface.

  @AC-1
  Scenario: Favoriting an article marks it favorited and increments the count
    Given a registered author "amy" with an article "hello"
    And a registered reader "ben"
    When "ben" favorites the article "hello"
    Then the article "hello" is favorited by "ben" with favorites count 1

  @AC-1
  Scenario: Unfavoriting reverses it
    Given a registered author "cara" with an article "post"
    And a registered reader "dan"
    And "dan" has favorited the article "post"
    When "dan" unfavorites the article "post"
    Then the article "post" is not favorited by "dan" with favorites count 0

  @AC-1
  Scenario: Favoriting is idempotent
    Given a registered author "eve" with an article "idem"
    And a registered reader "finn"
    And "finn" has favorited the article "idem"
    When "finn" favorites the article "idem"
    Then the article "idem" is favorited by "finn" with favorites count 1

  @AC-2
  Scenario: A reader can add a comment to an article
    Given a registered author "gwen" with an article "discuss"
    And a registered reader "hank"
    When "hank" comments "nice post" on the article "discuss"
    Then the article "discuss" has 1 comment
    And the first comment body is "nice post" by "hank"

  @AC-2
  Scenario: Listing comments returns them with authors
    Given a registered author "ida" with an article "threaded"
    And a registered reader "jack"
    And "jack" has commented "first" on the article "threaded"
    When the comments for article "threaded" are listed
    Then there is 1 comment authored by "jack"

  @AC-4
  Scenario: The comment author can delete their own comment
    Given a registered author "kate" with an article "removable"
    And a registered reader "leo"
    And "leo" has commented "temp" on the article "removable"
    When "leo" deletes their comment on "removable"
    Then the article "removable" has 0 comments

  @AC-4
  Scenario: A non-author cannot delete someone else's comment
    Given a registered author "mia" with an article "guarded"
    And a registered reader "ned"
    And a registered reader "olga"
    And "ned" has commented "mine" on the article "guarded"
    When "olga" tries to delete "ned"'s comment on "guarded"
    Then the comment deletion is rejected as forbidden

  @AC-2
  Scenario: Adding a comment requires a body
    Given a registered author "pat" with an article "empty"
    And a registered reader "quinn"
    When "quinn" comments "" on the article "empty"
    Then the comment creation is rejected with a validation error

  @AC-1
  Scenario: Favoriting a non-existent article is not found
    Given a registered reader "rae"
    When "rae" favorites the article "ghost"
    Then the favorite request is rejected as not found
