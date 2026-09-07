#!/usr/bin/env bash
# license-checker-tsv.sh — runs license-checker over the current directory (a delta_diff root) and
# emits rule\tfile\tmessage lines, one per package whose license matches AIRE_DISALLOWED_LICENSES
# (exported by run-static-evals.sh from tests/.evals/config.json thresholds.disallowedLicenses,
# per common/ci-pipeline-generation.md Section 3.0c — the threshold, never a hardcoded copy of it).
set -uo pipefail
BAD="${AIRE_DISALLOWED_LICENSES:-}"
npx --yes license-checker --json --excludePrivatePackages 2>/dev/null | jq -r --arg bad "$BAD" '
  ($bad | split(",")) as $disallowed |
  to_entries[] |
  select(.value.licenses as $l | $disallowed | index($l)) |
  ["license", .key, .value.licenses] | @tsv
'
