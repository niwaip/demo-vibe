#!/usr/bin/env bash
set -euo pipefail

# Test script for the foundation layer
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source the test harness
source "${SCRIPT_DIR}/harness.sh"

# Source the wp-common library
source "${PROJECT_DIR}/lib/wp-common.sh"

# Set up test environment
WP_SESSION="${PROJECT_DIR}/test_session"
export WP_SESSION

# Path to wp script
WP_SCRIPT="${PROJECT_DIR}/bin/wp"

# Cleanup function
cleanup() {
    rm -rf "$WP_SESSION"
}

# Set up trap for cleanup
trap cleanup EXIT

# Create a test file
TEST_FILE="${PROJECT_DIR}/test_draft.txt"
echo "This is a test file. It has some words." > "$TEST_FILE"

echo "=== Testing wp-common.sh functions ==="

# Test wp_session_dir
echo ""
echo "--- Testing wp_session_dir ---"
result=$(wp_session_dir)
assert_eq "wp_session_dir returns WP_SESSION value" "$WP_SESSION" "$result"

# Test wp_log (capture stderr)
echo ""
echo "--- Testing wp_log ---"
log_result=$(wp_log INFO "test message" 2>&1)
assert_contains "wp_log INFO contains level" "$log_result" "[INFO]"
assert_contains "wp_log INFO contains message" "$log_result" "test message"

log_result=$(wp_log WARN "warning test" 2>&1)
assert_contains "wp_log WARN contains level" "$log_result" "[WARN]"

log_result=$(wp_log ERR "error test" 2>&1)
assert_contains "wp_log ERR contains level" "$log_result" "[ERR]"

# Test wp_escape_sed
echo ""
echo "--- Testing wp_escape_sed ---"
result=$(wp_escape_sed "test/string")
assert_eq "wp_escape_sed escapes forward slash" "test\/string" "$result"

result=$(wp_escape_sed "test.file")
assert_eq "wp_escape_sed escapes dot" "test\.file" "$result"

result=$(wp_escape_sed "test[0]")
assert_eq "wp_escape_sed escapes brackets" "test\[0\]" "$result"

# Test wp_require_cmd
echo ""
echo "--- Testing wp_require_cmd ---"
wp_require_cmd bash
assert_exit_code "wp_require_cmd with existing command" 0 $?

# Test wp_require_cmd with missing command (subshell)
exit_code=0
(wp_require_cmd nonexistent_command_xyz 2>/dev/null) || exit_code=$?
assert_exit_code "wp_require_cmd with missing command exits 127" 127 "$exit_code"

echo ""
echo "=== Testing wp init ==="

# Clean up any existing session
cleanup

# Test wp init
"$WP_SCRIPT" init "$TEST_FILE"
assert_exit_code "wp init succeeds" 0 $?

# Check directory structure
assert_eq "wp init creates session dir" "1" "$(test -d "$WP_SESSION" && echo 1 || echo 0)"
assert_eq "wp init creates history dir" "1" "$(test -d "$WP_SESSION/history" && echo 1 || echo 0)"
assert_eq "wp init creates current symlink" "1" "$(test -L "$WP_SESSION/current" && echo 1 || echo 0)"
assert_eq "wp init creates meta file" "1" "$(test -f "$WP_SESSION/meta" && echo 1 || echo 0)"
assert_eq "wp init creates first snapshot" "1" "$(test -f "$WP_SESSION/history/0001.txt" && echo 1 || echo 0)"

# Check meta file content
source_line=$(grep '^source=' "$WP_SESSION/meta" | cut -d'=' -f2)
assert_eq "wp init sets correct source file" "test_draft.txt" "$source_line"

echo ""
echo "=== Testing wp_current ==="

# wp_current should return the current snapshot path
current_result=$(wp_current)
assert_contains "wp_current returns snapshot path" "$current_result" "0001.txt"

# Test wp_current fails when no session
cleanup
result=$(wp_current 2>&1) || exit_code=$?
assert_exit_code "wp_current fails when no session" 1 "${exit_code:-0}"
assert_contains "wp_current error message" "$result" "No active session"

# Restore session for more tests
"$WP_SCRIPT" init "$TEST_FILE"

echo ""
echo "=== Testing wp_seq ==="

seq_result=$(wp_seq)
assert_eq "wp_seq returns correct sequence" "1" "$seq_result"

echo ""
echo "=== Testing wp_commit ==="

# Test wp_commit
echo "New content for snapshot 2" | wp_commit
assert_eq "wp_commit creates second snapshot" "1" "$(test -f "$WP_SESSION/history/0002.txt" && echo 1 || echo 0)"

seq_result=$(wp_seq)
assert_eq "wp_commit increments sequence" "2" "$seq_result"

# Test current symlink points to new snapshot
current_result=$(wp_current)
assert_contains "wp_commit updates current symlink" "$current_result" "0002.txt"

echo ""
echo "=== Testing wp save ==="

# Save to a test output file
SAVE_OUTPUT="${PROJECT_DIR}/test_save_output.txt"
"$WP_SCRIPT" save "$SAVE_OUTPUT"
assert_exit_code "wp save succeeds" 0 $?

saved_content=$(cat "$SAVE_OUTPUT")
expected_content="New content for snapshot 2"
assert_eq "wp save writes correct content" "$expected_content" "$saved_content"

rm -f "$SAVE_OUTPUT"

echo ""
echo "=== Testing wp status ==="

status_output=$("$WP_SCRIPT" status)
assert_contains "wp status shows source" "$status_output" "test_draft.txt"
assert_contains "wp status shows snapshot number" "$status_output" "Snapshot: 2"
assert_contains "wp status shows word count" "$status_output" "Words:"

echo ""
echo "=== Testing wp pipe ==="

pipe_output=$("$WP_SCRIPT" pipe)
assert_eq "wp pipe outputs current snapshot" "New content for snapshot 2" "$pipe_output"

echo ""
echo "=== Testing wp init with nonexistent file ==="

cleanup
result=$("$WP_SCRIPT" init nonexistent_file_xyz.txt 2>&1) || exit_code=$?
assert_exit_code "wp init fails with nonexistent file" 1 "${exit_code:-0}"
assert_contains "wp init error message for nonexistent file" "$result" "File not found"

echo ""
echo "=== Testing wp clean ==="

# Reinitialize for clean test
"$WP_SCRIPT" init "$TEST_FILE"
assert_eq "Session exists before clean" "1" "$(test -d "$WP_SESSION" && echo 1 || echo 0)"

# Clean with 'y' response
clean_result=$(echo "y" | "$WP_SCRIPT" clean 2>&1)
assert_eq "wp clean removes session dir" "0" "$(test -d "$WP_SESSION" && echo 1 || echo 0)"

echo ""
echo "=== Testing unknown command ==="

result=$("$WP_SCRIPT" unknown_cmd 2>&1) || exit_code=$?
assert_exit_code "Unknown command exits 1" 1 "${exit_code:-0}"
assert_contains "Unknown command shows usage" "$result" "Usage"

# Clean up test file
rm -f "$TEST_FILE"

echo ""
echo "=== All tests complete ==="
report