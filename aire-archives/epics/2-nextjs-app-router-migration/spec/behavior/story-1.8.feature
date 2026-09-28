Feature: Article Editor & Profile Page
  As an author
  I want to create and edit my articles, and view my own or another user's profile
  So that I can manage my content and see article/follower context for any user

  # Story 1.8 — Covers REQ-F-22, REQ-F-23
  # Bound to the editor payload builder + the profile-page data assembler.

  @AC-1
  Scenario: The editor builds a Conduit article payload with parsed tags
    When the editor form is submitted with title "My Post", description "d", body "b" and tags "react, next"
    Then the article payload has title "My Post" and tag list "react" and "next"

  @AC-1
  Scenario: The editor parses an empty tag string to an empty list
    When the editor form is submitted with title "No Tags", description "d", body "b" and tags ""
    Then the article payload has an empty tag list

  @AC-2
  Scenario: The profile page shows a user's own articles
    Given a registered author "amy" with articles "one" and "two"
    When the profile page for "amy" is assembled for an anonymous viewer
    Then the profile is for "amy"
    And the profile page lists 2 of the user's own articles

  @AC-2
  Scenario: The profile page shows the user's favorited articles
    Given a registered author "ben" with articles "x"
    And a registered reader "cara" who has favorited "x"
    When the profile page for "cara" is assembled for an anonymous viewer
    Then the profile page lists 1 favorited article

  @AC-2
  Scenario: The profile page reflects the viewer's following status
    Given a registered author "dan" with articles "post"
    And a registered reader "eve" who follows "dan"
    When the profile page for "dan" is assembled for viewer "eve"
    Then the profile following flag is true

  @AC-2
  Scenario: Assembling a profile page for an unknown user is not found
    When the profile page for "ghost" is assembled for an anonymous viewer
    Then the profile page request is rejected as not found
