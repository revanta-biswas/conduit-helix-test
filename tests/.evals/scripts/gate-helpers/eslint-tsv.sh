#!/usr/bin/env bash
# eslint-tsv.sh [complexity-only] — runs eslint over the current directory (a delta_diff root,
# already cd'd there by run-static-evals.sh) and emits rule\tfile\tmessage lines, one per eslint
# message. With arg1="complexity", only the `complexity` rule's messages are emitted (used by D6,
# so D1 and D6 never double-count the same finding under two different gate ids).
set -uo pipefail
FILTER="${1:-}"
out="$(npx --yes eslint . --format json 2>/dev/null)"
if [ "$FILTER" = "complexity" ]; then
  echo "$out" | jq -r '.[] | .filePath as $f | .messages[] | select(.ruleId == "complexity") | [.ruleId, $f, .message] | @tsv'
else
  echo "$out" | jq -r '.[] | .filePath as $f | .messages[] | [(.ruleId // "eslint-error"), $f, .message] | @tsv'
fi
