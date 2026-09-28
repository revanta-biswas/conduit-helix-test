#!/usr/bin/env bash
# CR test fixture — restore / teardown / status
#
# The epic cycle in this workspace is ARCHIVED (archive-epic removed the live
# spec/, reports/ and runtime-artifacts/ trees). epic-change-request refuses to
# run on an archived cycle by design, so testing it needs the cycle restored
# from its own archive into a scratch branch.
#
#   ./cr-test-fixture.sh restore   # rebuild the live cycle from the archive on a test branch
#   ./cr-test-fixture.sh status    # what state is the workspace in right now
#   ./cr-test-fixture.sh teardown  # drop the test branch, return to where you were
#
# Nothing here touches the archive, main, or epic/nextjs-migration's history.

set -euo pipefail
cd "$(dirname "$0")"

ARCHIVE="aire-archives/epics/2-nextjs-app-router-migration"
TEST_BRANCH="cr-test/epic-nextjs-migration"
ORIG_BRANCH_FILE=".git/cr-test-origin-branch"

die() { echo "ERROR: $*" >&2; exit 1; }

status() {
  echo "branch           : $(git branch --show-current)"
  echo "working tree     : $(if [ -z "$(git status --porcelain)" ]; then echo clean; else echo "dirty ($(git status --porcelain | wc -l | tr -d ' ') paths)"; fi)"
  for d in spec/plans runtime-artifacts reports; do
    printf "%-17s: %s\n" "$d" "$([ -d "$d" ] && echo present || echo ABSENT)"
  done
  printf "%-17s: %s\n" "archive" "$([ -d "$ARCHIVE" ] && echo present || echo ABSENT)"
  if [ -f runtime-artifacts/aire-state.md ]; then
    echo "stories in tracker: $(grep -cE '^\| [0-9]+\.[0-9]+ \|' runtime-artifacts/aire-state.md || echo 0)"
  fi
  echo "CR framework     : $([ -f aire-workflow/workflows/epic-change-request.md ] && echo present || echo ABSENT)"
}

restore() {
  [ -d "$ARCHIVE" ] || die "archive not found at $ARCHIVE"

  git branch --show-current > "$ORIG_BRANCH_FILE"
  git checkout -b "$TEST_BRANCH" 2>/dev/null || git checkout "$TEST_BRANCH"

  # The framework sync (CLAUDE.md, aire-workflow/, .claude/skills/) is typically
  # uncommitted in this workspace. Carry it onto the test branch and commit it there,
  # so the branch holds the exact framework under test. Nothing is pushed.
  if [ -n "$(git status --porcelain)" ]; then
    echo "committing the in-place framework sync onto $TEST_BRANCH..."
    git add -A >/dev/null
    git commit -qm "test fixture: framework under test (CR workflow + supporting rules)" || true
  fi

  echo "restoring live cycle from the archive..."
  mkdir -p spec/plans
  cp -R "$ARCHIVE/spec/plans/." spec/plans/
  [ -d "$ARCHIVE/spec/behavior" ]   && cp -R "$ARCHIVE/spec/behavior" spec/   || true
  [ -f "$ARCHIVE/spec/behavior.feature" ] && cp "$ARCHIVE/spec/behavior.feature" spec/ || true
  [ -d "$ARCHIVE/spec/test-plans" ] && cp -R "$ARCHIVE/spec/test-plans" spec/ || true
  cp -R "$ARCHIVE/runtime-artifacts" .
  [ -d "$ARCHIVE/reports" ] && cp -R "$ARCHIVE/reports" . || true

  # --- make the restored cycle actually satisfy epic-change-request Phase 0 ---
  if [ -f runtime-artifacts/aire-state.md ]; then
    # (a) the cycle must look open, not closed
    sed -i '' 's/^- Epic PR: .*/- Epic PR: (not raised — restored fixture)/' runtime-artifacts/aire-state.md 2>/dev/null || true
    # (b) Epic Branch must name the branch we are actually on, or Phase 0 item 5
    #     checks out the real epic branch and the fixture disappears
    sed -i '' "s|^- Epic Branch: .*|- Epic Branch: $TEST_BRANCH|" runtime-artifacts/aire-state.md
    # (c) LOCAL tracker by default: the real cycle is GITHUB, and Phase 10.1 would
    #     create a real issue and move a real milestone. Set CR_TEST_TRACKER=keep
    #     to leave it as GITHUB when you deliberately want to test live tracker calls.
    if [ "${CR_TEST_TRACKER:-local}" = "local" ]; then
      sed -i '' 's|^- Type: .*|- Type: LOCAL|' runtime-artifacts/aire-state.md
      sed -i '' 's|^- Parent Epic: .*|- Parent Epic: none|' runtime-artifacts/aire-state.md
      sed -i '' 's|^- Epic URL: .*|- Epic URL: —|' runtime-artifacts/aire-state.md
      sed -i '' 's/| #\([0-9]*\) |/| LOCAL |/g' runtime-artifacts/aire-state.md
      echo "tracker set to LOCAL (no external calls). CR_TEST_TRACKER=keep to use GITHUB."
    else
      echo "tracker left as GITHUB — runs past the gate WILL create issues and move the milestone."
    fi
  fi

  # (d) Phase 0 item 6 halts when aire-archives/epics/<EPIC-ID>-*/ exists.
  #     Park the archive out of the glob's way; teardown puts it back.
  if [ -d "$ARCHIVE" ]; then
    mkdir -p .cr-test-parked
    cp -R "$ARCHIVE" ".cr-test-parked/$(basename "$ARCHIVE")"
    rm -rf "$ARCHIVE"
    echo "archive parked at .cr-test-parked/ so the cycle reads as OPEN (restored via teardown)."
  fi

  git add -A >/dev/null
  git commit -qm "test fixture: restore live cycle from archive for epic-change-request testing" || true
  echo
  echo "restored on branch $TEST_BRANCH"
  echo
  status
}

teardown() {
  local orig="main"
  [ -f "$ORIG_BRANCH_FILE" ] && orig="$(cat "$ORIG_BRANCH_FILE")"

  # Commit anything outstanding so `git checkout` cannot refuse (the fixture script
  # itself is often edited mid-test and would otherwise block the switch).
  if [ -n "$(git status --porcelain)" ]; then
    git add -A >/dev/null; git commit -qm "test fixture: wip before teardown" || true
  fi

  local tip; tip="$(git rev-parse "$TEST_BRANCH" 2>/dev/null || echo)"
  git checkout -q "$orig" 2>/dev/null || die "could not check out $orig"

  # 🔴 The framework under test was committed ONTO the test branch, so deleting the
  # branch would take the only copy with it. Restore the framework + fixture to the
  # original branch's WORKING TREE (uncommitted, exactly as they were found) first.
  if [ -n "$tip" ]; then
    git checkout "$tip" -- CLAUDE.md aire-workflow .claude cr-test-fixture.sh 2>/dev/null || true
    echo "framework + fixture returned to the working tree of $orig (uncommitted)"
  fi

  # The restored cycle trees belong to the fixture only — remove them from $orig.
  rm -rf spec/plans spec/behavior spec/behavior.feature spec/test-plans runtime-artifacts reports 2>/dev/null || true

  # Put the parked archive back.
  if [ -d ".cr-test-parked" ]; then
    mkdir -p aire-archives/epics
    cp -R .cr-test-parked/* aire-archives/epics/ 2>/dev/null || true
    rm -rf .cr-test-parked
    echo "archive restored from .cr-test-parked/"
  fi

  # Keep the branch by default — it is the only record of the test run.
  # CR_TEST_DELETE_BRANCH=1 to drop it once you are done.
  if [ "${CR_TEST_DELETE_BRANCH:-0}" = "1" ]; then
    git branch -D "$TEST_BRANCH" 2>/dev/null || true
    echo "test branch deleted"
  else
    echo "test branch kept at $TEST_BRANCH (CR_TEST_DELETE_BRANCH=1 to delete)"
  fi
  rm -f "$ORIG_BRANCH_FILE"
  echo "torn down; back on $orig"
  status
}

case "${1:-status}" in
  restore)  restore ;;
  teardown) teardown ;;
  status)   status ;;
  *) die "usage: $0 [restore|status|teardown]" ;;
esac
