#!/usr/bin/env bash
# test-spell-integration.sh - Integration tests for full spell pipeline
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/harness.sh"

WP_ROOT="$(dirname "$SCRIPT_DIR")"
BIN_SPELL="${WP_ROOT}/bin/spell"

# Test 1: Document with no misspellings
echo "Test 1: Document with no misspellings"
RESULT=$(echo "The cat sat on the mat" | "${BIN_SPELL}/wp-spell")
assert_eq "spell-integration: no errors on correct doc" "" "$RESULT"

# Test 2: Document with 2 known misspellings
echo "Test 2: Document with 2 known misspellings"
RESULT=$(echo "The kittne sat on the matt" | "${BIN_SPELL}/wp-spell")
assert_contains "spell-integration: kittne flagged" "$RESULT" "kittne"
assert_contains "spell-integration: matt flagged" "$RESULT" "matt"

# Test 3: Misspelled word in mixed case (normalization working)
echo "Test 3: Misspelled word in mixed case"
RESULT=$(echo "The KiTTnE sat on the mat" | "${BIN_SPELL}/wp-spell")
assert_contains "spell-integration: mixed case caught" "$RESULT" "kittne"

# Test 4: Word added via -a, re-run
echo "Test 4: Word added via -a, re-run"
TMP_DICT=$(mktemp)
cp "${WP_ROOT}/lib/dictionary.txt" "$TMP_DICT"
trap "rm -f $TMP_DICT" EXIT

# Add 'kittne' to temp dict
"${BIN_SPELL}/wp-spell" -d "$TMP_DICT" -a "kittne" > /dev/null 2>&1

# Re-check - kittne should no longer be flagged
RESULT=$(echo "The kittne sat on the matt" | "${BIN_SPELL}/wp-spell" -d "$TMP_DICT")
assert_not_contains "spell-integration: kittne resolved after add" "$RESULT" "kittne"
assert_contains "spell-integration: matt still flagged" "$RESULT" "matt"

# Test 5: --count on document with 3 errors
echo "Test 5: --count on document with 3 errors"
RESULT=$(echo "The kittne sat on the matt with a graat" | "${BIN_SPELL}/wp-spell" --count)
assert_eq "spell-integration: count 3 errors" "3" "$RESULT"

# Test 6: Piped input with misspelling works without a session
echo "Test 6: Piped input without session"
RESULT=$(echo "The kittne sat" | "${BIN_SPELL}/wp-spell")
assert_contains "spell-integration: piped input works" "$RESULT" "kittne"

# Test 7: Full pipeline manual invocation (each stage chained)
echo "Test 7: Manual pipeline invocation"
RESULT=$(echo "The kittne sat on the matt" \
  | "${BIN_SPELL}/wp-spell-words" \
  | "${BIN_SPELL}/wp-spell-lower" \
  | sort \
  | "${BIN_SPELL}/wp-spell-unique" \
  | "${BIN_SPELL}/wp-spell-mismatch")
assert_contains "spell-integration: manual kittne" "$RESULT" "kittne"
assert_contains "spell-integration: manual matt" "$RESULT" "matt"
# Ensure 'the', 'sat', 'on' are NOT in output (they're in dictionary)
assert_not_contains "spell-integration: no 'the'" "$RESULT" "the"
assert_not_contains "spell-integration: no 'sat'" "$RESULT" "sat"

report