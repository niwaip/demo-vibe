#!/usr/bin/env bash
# test-stats.sh - Test suite for wp-stats

source "$(dirname "$0")/harness.sh"

WP_STATS="$(dirname "$0")/../bin/wp-stats"
SAMPLE="$(dirname "$0")/fixtures/sample.txt"

# Expected values for sample.txt
EXPECTED_WORDS=50
EXPECTED_LINES=4
EXPECTED_SENTENCES=5
EXPECTED_PARAGRAPHS=3

# Test 1: Known input, -w flag
WORD_COUNT=$($WP_STATS -w "$SAMPLE")
assert_eq "Known input, -w flag" "$EXPECTED_WORDS" "$WORD_COUNT"

# Test 2: Known input, -l flag
LINE_COUNT=$($WP_STATS -l "$SAMPLE")
assert_eq "Known input, -l flag" "$EXPECTED_LINES" "$LINE_COUNT"

# Test 3: Known input, -s flag
SENTENCE_COUNT=$($WP_STATS -s "$SAMPLE")
assert_eq "Known input, -s flag" "$EXPECTED_SENTENCES" "$SENTENCE_COUNT"

# Test 4: Known input, -p flag
PARAGRAPH_COUNT=$($WP_STATS -p "$SAMPLE")
assert_eq "Known input, -p flag" "$EXPECTED_PARAGRAPHS" "$PARAGRAPH_COUNT"

# Test 5: --freq 3 on known input
FREQ_OUTPUT=$($WP_STATS --freq 3 "$SAMPLE")
assert_contains "--freq 3 on known input" "$FREQ_OUTPUT" "fox"
assert_contains "--freq 3 output contains word" "$FREQ_OUTPUT" "evolve"

# Test 6: Empty input
EMPTY_OUTPUT=$(echo "" | $WP_STATS)
EMPTY_EXIT=$?
assert_eq "Empty input exits 0" "0" "$EMPTY_EXIT"
assert_contains "Empty input shows zeros" "$EMPTY_OUTPUT" "Words          :          0"

# Test 7: Single word, no newline
SINGLE_WORD=$(echo -n "test" | $WP_STATS -w)
assert_eq "Single word, no newline" "1" "$SINGLE_WORD"

# Test 8: -c flag for character count
CHAR_COUNT=$($WP_STATS -c "$SAMPLE")
assert_eq "Known input, -c flag" "354" "$CHAR_COUNT"

# Test 9: Full report format
FULL_REPORT=$($WP_STATS "$SAMPLE")
assert_contains "Full report has header" "$FULL_REPORT" "Document Statistics"
assert_contains "Full report has separator" "$FULL_REPORT" "──────────"

# Test 10: wp-stats never modifies session directory
# Create a temp session directory and verify it's unchanged after running wp-stats
TEMP_SESSION=$(mktemp -d)
mkdir -p "$TEMP_SESSION/history"
WP_SESSION="$TEMP_SESSION" $WP_STATS "$SAMPLE" > /dev/null
SESSION_FILES_AFTER=$(ls -A "$TEMP_SESSION/history" 2>/dev/null || echo "")
assert_eq "wp-stats never modifies session" "" "$SESSION_FILES_AFTER"
rm -rf "$TEMP_SESSION"

report