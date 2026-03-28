#!/usr/bin/env bash
set -euo pipefail

# Test script for wp-search
source "$(dirname "$0")/harness.sh"

# Get the absolute path to bin/wp-search
WP_SEARCH="$(dirname "$0")/../bin/wp-search"
WP_SEARCH=$(readlink -f "$WP_SEARCH")

# Setup: Create a temp session directory
setup() {
    export WP_SESSION=$(mktemp -d)
    mkdir -p "${WP_SESSION}/history"
    echo "seq=0001" > "${WP_SESSION}/meta"
}

# Teardown: Remove temp session
teardown() {
    rm -rf "${WP_SESSION:-}"
}

# Helper to get current snapshot content
get_current() {
    cat "$(readlink -f "${WP_SESSION}/current")"
}

# Helper to set current snapshot content
set_current() {
    local content="$1"
    local seq
    seq=$(grep '^seq=' "${WP_SESSION}/meta" | cut -d'=' -f2)
    local seq_num=$((10#$seq))
    local new_seq=$(printf '%04d' $((seq_num + 1)))
    local snapshot="${WP_SESSION}/history/${new_seq}.txt"
    echo "$content" > "$snapshot"
    rm -f "${WP_SESSION}/current"
    ln -s "$snapshot" "${WP_SESSION}/current"
    sed -i "s/^seq=.*/seq=${new_seq}/" "${WP_SESSION}/meta"
}

# Helper to reset with initial content
reset_content() {
    local content="$1"
    echo "seq=0000" > "${WP_SESSION}/meta"
    rm -f "${WP_SESSION}/current"
    local snapshot="${WP_SESSION}/history/0001.txt"
    echo "$content" > "$snapshot"
    ln -s "$snapshot" "${WP_SESSION}/current"
    sed -i "s/^seq=.*/seq=0001/" "${WP_SESSION}/meta"
}

# Test 1: Simple literal replace
test_simple_replace() {
    setup
    reset_content "The cat sat on the mat."

    # Run wp-search
    echo "The cat sat on the mat." | "$WP_SEARCH" "cat" "dog" > /dev/null 2>&1

    local result
    result=$(get_current)
    assert_eq "Simple literal replace" "The dog sat on the mat." "$result"

    teardown
}

# Test 2: Case-insensitive -i
test_case_insensitive() {
    setup
    reset_content "Cat CAT cat cAt"

    echo "Cat CAT cat cAt" | "$WP_SEARCH" -i "cat" "dog" > /dev/null 2>&1

    local result
    result=$(get_current)
    assert_eq "Case-insensitive replace" "dog dog dog dog" "$result"

    teardown
}

# Test 3: ERE pattern -r
test_ere_pattern() {
    setup
    reset_content "Mr. Smith and Mrs. Jones"

    echo "Mr. Smith and Mrs. Jones" | "$WP_SEARCH" -r '\b(Mr|Mrs)\.' 'Mx.' > /dev/null 2>&1

    local result
    result=$(get_current)
    assert_eq "ERE pattern replace" "Mx. Smith and Mx. Jones" "$result"

    teardown
}

# Test 4: -n 2 flag (only 2nd occurrence)
test_nth_occurrence() {
    setup
    reset_content "cat cat cat cat"

    echo "cat cat cat cat" | "$WP_SEARCH" -n 2 "cat" "dog" > /dev/null 2>&1

    local result
    result=$(get_current)
    assert_eq "Nth occurrence replace (n=2)" "cat dog cat cat" "$result"

    teardown
}

# Test 5: Preview mode -p
test_preview_mode() {
    setup
    reset_content "hello world"

    local initial_seq
    initial_seq=$(grep '^seq=' "${WP_SESSION}/meta" | cut -d'=' -f2)

    # Run in preview mode
    local output
    output=$(echo "hello world" | "$WP_SEARCH" -p "hello" "goodbye" 2>&1) || true

    local final_seq
    final_seq=$(grep '^seq=' "${WP_SESSION}/meta" | cut -d'=' -f2)

    # Sequence should not change
    assert_eq "Preview mode does not change seq" "$initial_seq" "$final_seq"

    # Output should contain diff markers
    assert_contains "Preview mode shows diff markers" "$output" "goodbye"

    teardown
}

# Test 6: Pattern with / character
test_pattern_with_slash() {
    setup
    reset_content "path/to/file and path/to/another"

    echo "path/to/file and path/to/another" | "$WP_SEARCH" "path/to/file" "new/path" > /dev/null 2>&1

    local result
    result=$(get_current)
    assert_eq "Pattern with / character" "new/path and path/to/another" "$result"

    teardown
}

# Test 7: No match - input passes through unchanged
test_no_match() {
    setup
    reset_content "The dog barks."

    local exit_code=0
    echo "The dog barks." | "$WP_SEARCH" "cat" "bird" > /dev/null 2>&1 || exit_code=$?

    assert_exit_code "No match returns exit 0" 0 "$exit_code"

    local result
    result=$(get_current)
    assert_eq "No match - input unchanged" "The dog barks." "$result"

    teardown
}

# Test 8: Empty input
test_empty_input() {
    setup
    reset_content ""

    local exit_code=0
    echo "" | "$WP_SEARCH" "cat" "dog" > /dev/null 2>&1 || exit_code=$?

    assert_exit_code "Empty input returns exit 0" 0 "$exit_code"

    teardown
}

# Test 9: Pattern with backslash character
test_pattern_with_backslash() {
    setup
    reset_content 'test \ backslash'

    # Use $'...' syntax to pass a single backslash
    echo 'test \ backslash' | "$WP_SEARCH" $'\\' "backslash" > /dev/null 2>&1

    local result
    result=$(get_current)
    assert_eq "Pattern with backslash character" 'test backslash backslash' "$result"

    teardown
}

# Run all tests
test_simple_replace
test_case_insensitive
test_ere_pattern
test_nth_occurrence
test_preview_mode
test_pattern_with_slash
test_no_match
test_empty_input
test_pattern_with_backslash

report