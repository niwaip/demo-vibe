#!/usr/bin/env bash
# test-e2e.sh - End-to-end session integration test
# Simulates a full editing session using all tools together
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/harness.sh"

WP_ROOT="$(dirname "$SCRIPT_DIR")"
PATH="${WP_ROOT}/bin:${PATH}"
source "${WP_ROOT}/lib/wp-common.sh"

# Use isolated session directory for this test
export WP_SESSION="${WP_ROOT}/session-e2e-test"

cleanup() {
    rm -rf "$WP_SESSION"
}
trap cleanup EXIT

# Setup: create test document and init session
echo "Setup: Creating test document"
TEST_DOC="/tmp/test-doc-e2e.txt"
echo "The kittne sat on the matt. It was a grate day." > "$TEST_DOC"

echo "Init session"
wp init "$TEST_DOC"

# Spell check
echo "Test: Spell check"
ERRORS=$(wp pipe | "${WP_ROOT}/bin/spell/wp-spell")
assert_contains "e2e: kittne flagged" "$ERRORS" "kittne"
assert_contains "e2e: matt flagged" "$ERRORS" "matt"
assert_contains "e2e: grate flagged" "$ERRORS" "grate"

# Fix a word
echo "Test: Fix 'kittne' -> 'kitten'"
wp run wp-search "kittne" "kitten"
assert_eq "e2e: seq incremented" "2" "$(wp_seq)"

# Verify fix
echo "Test: Verify fix"
ERRORS_AFTER=$(wp pipe | "${WP_ROOT}/bin/spell/wp-spell")
assert_not_contains "e2e: kittne resolved" "$ERRORS_AFTER" "kittne"
assert_contains "e2e: matt still flagged" "$ERRORS_AFTER" "matt"

# Stats
echo "Test: Word count"
WORDS=$(wp pipe | "${WP_ROOT}/bin/wp-stats" -w)
assert_eq "e2e: word count" "11" "$WORDS"

# Undo
echo "Test: Undo"
"${WP_ROOT}/bin/wp-undo"
assert_eq "e2e: undo restores seq" "1" "$(wp_seq)"

# Verify original error is back after undo
echo "Test: Verify undo restored error"
ERRORS_UNDONE=$(wp pipe | "${WP_ROOT}/bin/spell/wp-spell")
assert_contains "e2e: error back after undo" "$ERRORS_UNDONE" "kittne"

# Cleanup
echo "Cleanup"
wp clean --force

report