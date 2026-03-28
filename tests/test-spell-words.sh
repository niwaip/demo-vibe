#!/usr/bin/env bash
source "$(dirname "$0")/harness.sh"

SCRIPT_DIR="$(dirname "$0")"
SPELL_WORDS="${SCRIPT_DIR}/../bin/spell/wp-spell-words"

# Test 1: Basic punctuation
output=$(echo "Hello, world!" | "$SPELL_WORDS")
expected="Hello
world"
assert_eq "Basic punctuation handling" "$expected" "$output"

# Test 2: Hyphenated words
output=$(echo "time-sharing" | "$SPELL_WORDS")
expected="time
sharing"
assert_eq "Hyphenated words split" "$expected" "$output"

# Test 3: Numbers discarded
output=$(echo "Chapter 12" | "$SPELL_WORDS")
expected="Chapter"
assert_eq "Numbers discarded" "$expected" "$output"

# Test 4: Empty input
output=$(echo "" | "$SPELL_WORDS")
exit_code=$?
assert_eq "Empty input produces no output" "" "$output"
assert_exit_code "Empty input exits 0" 0 "$exit_code"

# Test 5: Contractions split
output=$(echo "won't stop" | "$SPELL_WORDS")
expected="won
t
stop"
assert_eq "Contractions split" "$expected" "$output"

# Test 6: Only punctuation
output=$(echo "..." | "$SPELL_WORDS")
assert_eq "Only punctuation produces no output" "" "$output"

report