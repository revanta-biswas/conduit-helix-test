#!/usr/bin/env bash
# npm-audit-tsv.sh — runs npm audit over the current directory (a delta_diff root) and emits
# rule\tfile\tmessage lines, one per vulnerable dependency.
#
# npm audit's `via` array mixes two shapes: an object (a real advisory, {source, title, ...}) or a
# bare string (a transitive-only entry naming just the offending package). Handle both — indexing
# .source on a string entry is a jq type error, not an empty result, so it aborted the whole
# pipeline (every finding lost, not just the malformed one) until this branch was added.
set -uo pipefail
npm audit --json 2>/dev/null | jq -r '
  .vulnerabilities // {} | to_entries[] |
  (.value.via[0]) as $via |
  if ($via | type) == "object" then
    [($via.source // .key | tostring), "package.json", ($via.title // (.key + " vulnerable"))]
  else
    [(.key), "package.json", ("via " + ($via | tostring) + " — " + .key + " vulnerable")]
  end | @tsv
'
