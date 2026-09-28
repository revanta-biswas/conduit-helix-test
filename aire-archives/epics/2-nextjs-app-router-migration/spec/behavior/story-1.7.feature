Feature: Home & Article Pages (Server Components)
  As a reader
  I want to browse the home feed and read individual articles with fast initial loads
  So that I get the same content faster, with proper SSR

  # Story 1.7 — Covers REQ-F-20, REQ-F-21, REQ-F-29
  # Bound to the feed-selection resolver + the home-page/article-page data assemblers.

  @AC-3
  Scenario: The global feed is the default when no feed param is given
    When the feed is resolved from no search params for an anonymous viewer
    Then the feed mode is "global"

  @AC-3
  Scenario: A tag search param selects the tag feed
    When the feed is resolved from search params with tag "react"
    Then the feed mode is "tag"
    And the resolved tag is "react"

  @AC-3
  Scenario: The personal feed is selected only when a viewer is present
    When the feed is resolved from search params with feed "personal" for a signed-in viewer
    Then the feed mode is "personal"

  @AC-3
  Scenario: The personal feed falls back to global for an anonymous viewer
    When the feed is resolved from search params with feed "personal" for an anonymous viewer
    Then the feed mode is "global"

  @AC-1
  Scenario: The home page shows the global feed and popular tags
    Given an author "amy" with articles "one" and "two" tagged "react"
    When the home page is assembled with no search params for an anonymous viewer
    Then the home page shows 2 articles
    And the home page popular tags include "react"

  @AC-1
  Scenario: The home page filters by tag
    Given an author "ben" with an article "tagged" tagged "elixir"
    And an author "ben2" with an article "plain"
    When the home page is assembled with tag "elixir" for an anonymous viewer
    Then the home page shows 1 article

  @AC-2
  Scenario: The article page shows the article and its comments
    Given an author "cara" with an article "readable"
    And "readable" has a comment "nice" by "dan"
    When the article page for "readable" is assembled for an anonymous viewer
    Then the article page article is "readable"
    And the article page shows 1 comment

  @AC-4
  Scenario: The article page for an unknown slug is not found
    When the article page for "ghost" is assembled for an anonymous viewer
    Then the article page request is rejected as not found
