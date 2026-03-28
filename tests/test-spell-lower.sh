#!/usr/bin/env bash
source "$(dirname "$0")/harness.sh"

SCRIPT="bin/spell/wp-spell-lower"

# Test 1: Hello -> hello
result=$(echo "Hello" | bash "$SCRIPT")
assert_eq "Hello -> hello" "hello" "$result"

# Test 2: UNIX -> unix
result=$(echo "UNIX" | bash "$SCRIPT")
assert_eq "UNIX -> unix" "unix" "$result"

# Test 3: already -> already
result=$(echo "already" | bash "$SCRIPT")
assert_eq "already -> already" "already" "$result"

# Test 4: MiXeD -> mixed
result=$(echo "MiXeD" | bash "$SCRIPT")
assert_eq "MiXeD -> mixed" "mixed" "$result"

# Test 5: empty string -> no output, exit 0
result=$(echo "" | bash "$SCRIPT")
exit_code=$?
assert_eq "empty string -> no output" "" "$result"
assert_exit_code "empty string exits 0" 0 "$exit_code"

# Test 6: three words on three lines -> three lowercase words on three lines
result=$(printf "The\nQuick\nBrown\n" | bash "$SCRIPT")
assert_eq "three words -> three lowercase" "the
quick
brown" "$result"

report