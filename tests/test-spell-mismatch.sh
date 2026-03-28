#!/usr/bin/env bash
# Test script for wp-spell-mismatch
# Note: The system dictionary (/usr/share/dict/words) is required for the main dictionary.
# On Debian/Ubuntu, install with: sudo apt-get install wamerican

source "$(dirname "$0")/harness.sh"

SCRIPT_DIR="$(dirname "$0")"
SPELL_MISMATCH="${SCRIPT_DIR}/../bin/spell/wp-spell-mismatch"
TEST_DICT="${SCRIPT_DIR}/fixtures/test-dict.txt"

# Test 1: All words in test dictionary - No output, exit 0
output=$(echo "cat" | "$SPELL_MISMATCH" -d "$TEST_DICT")
exit_code=$?
assert_eq "All words in test dictionary - no output" "" "$output"
assert_exit_code "All words in test dictionary - exit 0" 0 "$exit_code"

# Test 2: One misspelled word 'kittne' - Outputs 'kittne'
output=$(echo "kittne" | "$SPELL_MISMATCH" -d "$TEST_DICT")
expected="kittne"
assert_eq "One misspelled word outputs the word" "$expected" "$output"

# Test 3: Two misspelled words - Both output, one per line
output=$(echo -e "kittne\npuppey" | sort | "$SPELL_MISMATCH" -d "$TEST_DICT")
expected="kittne
puppey"
assert_eq "Two misspelled words output both" "$expected" "$output"

# Test 4: Empty input - No output, exit 0
output=$(echo "" | "$SPELL_MISMATCH" -d "$TEST_DICT")
exit_code=$?
assert_eq "Empty input - no output" "" "$output"
assert_exit_code "Empty input - exit 0" 0 "$exit_code"

# Test 5: -a flag adds word to a temp copy of the dictionary
# Create a temp copy of the test dict
TEMP_DICT=$(mktemp)
cp "$TEST_DICT" "$TEMP_DICT"

# Add 'mouse' to the temp dict
"$SPELL_MISMATCH" -d "$TEMP_DICT" -a "mouse"

# Verify mouse is now in the dict (no longer flagged)
output=$(echo "mouse" | "$SPELL_MISMATCH" -d "$TEMP_DICT")
assert_eq "Word added via -a no longer flagged" "" "$output"

# Cleanup
rm -f "$TEMP_DICT"

# Test 6: -d flag uses alternate dictionary
# Create a temp dict with just 'hello'
ALT_DICT=$(mktemp)
echo "hello" | sort > "$ALT_DICT"

output=$(echo "hello" | "$SPELL_MISMATCH" -d "$ALT_DICT")
assert_eq "-d flag uses alternate dictionary - known word" "" "$output"

output=$(echo "world" | "$SPELL_MISMATCH" -d "$ALT_DICT")
assert_eq "-d flag uses alternate dictionary - unknown word" "world" "$output"

# Cleanup
rm -f "$ALT_DICT"

report