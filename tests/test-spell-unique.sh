#!/usr/bin/env bash
source "$(dirname "$0")/harness.sh"

SCRIPT_DIR="$(dirname "$0")"
SPELL_UNIQUE="${SCRIPT_DIR}/../bin/spell/wp-spell-unique"

# Test 1: Basic duplicates
output=$(printf 'cat\ncat\ndog\n' | "$SPELL_UNIQUE")
expected="cat
dog"
assert_eq "Basic duplicates removed" "$expected" "$output"

# Test 2: All same word
output=$(printf 'the\nthe\nthe\n' | "$SPELL_UNIQUE")
expected="the"
assert_eq "All same word returns single word" "$expected" "$output"

# Test 3: No duplicates
output=$(printf 'apple\nberry\ncat\n' | "$SPELL_UNIQUE")
expected="apple
berry
cat"
assert_eq "No duplicates unchanged" "$expected" "$output"

# Test 4: Single word repeated 100 times
output=$(for i in $(seq 1 100); do echo "word"; done | "$SPELL_UNIQUE")
expected="word"
assert_eq "100 repeated words becomes one" "$expected" "$output"

# Test 5: Empty input
output=$(echo "" | "$SPELL_UNIQUE")
exit_code=$?
assert_eq "Empty input produces no output" "" "$output"
assert_exit_code "Empty input exits 0" 0 "$exit_code"

report