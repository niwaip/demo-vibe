#!/usr/bin/env bash
# test-undo.sh - Tests for wp-undo

source "$(dirname "$0")/harness.sh"
source "$(dirname "$0")/../lib/wp-common.sh"

# Path to wp-undo
WP_UNDO="$(dirname "$0")/../bin/wp-undo"

# Helper: create a session with N snapshots
# Each snapshot has different content to make diffs meaningful
_create_session_with_snapshots() {
    local count="$1"
    export WP_SESSION
    WP_SESSION=$(mktemp -d)

    mkdir -p "$WP_SESSION/history"

    for i in $(seq 1 "$count"); do
        local padded
        padded=$(printf '%04d' "$i")
        echo "Snapshot $i content. This is test content for snapshot number $i." > "$WP_SESSION/history/${padded}.txt"
    done

    # Set current to the last snapshot
    local last_padded
    last_padded=$(printf '%04d' "$count")
    ln -s "$WP_SESSION/history/${last_padded}.txt" "$WP_SESSION/current"
    echo "seq=${last_padded}" > "$WP_SESSION/meta"
}

# Helper: cleanup session
_cleanup_session() {
    if [[ -n "${WP_SESSION:-}" && -d "$WP_SESSION" ]]; then
        rm -rf "$WP_SESSION"
    fi
}

# Test 1: Step back once from snapshot 3
test_step_back_once() {
    _create_session_with_snapshots 3
    trap '_cleanup_session' EXIT

    "$WP_UNDO"
    local seq
    seq=$(wp_seq)

    assert_eq "Step back once from snapshot 3" "2" "$seq"

    _cleanup_session
    trap - EXIT
}

# Test 2: Step back -n 2 from snapshot 4
test_step_back_two() {
    _create_session_with_snapshots 4
    trap '_cleanup_session' EXIT

    "$WP_UNDO" -n 2
    local seq
    seq=$(wp_seq)

    assert_eq "Step back -n 2 from snapshot 4" "2" "$seq"

    _cleanup_session
    trap - EXIT
}

# Test 3: Step back from snapshot 1 - should error
test_step_back_from_oldest() {
    _create_session_with_snapshots 1
    trap '_cleanup_session' EXIT

    local output
    local exit_code
    output=$("$WP_UNDO" 2>&1)
    exit_code=$?

    assert_exit_code "Step back from snapshot 1 exits with code 1" 1 "$exit_code"
    assert_contains "Step back from snapshot 1 shows error" "$output" "Already at oldest snapshot"

    # Verify seq unchanged
    local seq
    seq=$(wp_seq)
    assert_eq "Step back from snapshot 1 leaves seq unchanged" "1" "$seq"

    _cleanup_session
    trap - EXIT
}

# Test 4: --list shows all snapshots
test_list_history() {
    _create_session_with_snapshots 3
    trap '_cleanup_session' EXIT

    local output
    output=$("$WP_UNDO" --list 2>&1)

    assert_contains "--list shows snapshot 0001" "$output" "[0001]"
    assert_contains "--list shows snapshot 0002" "$output" "[0002]"
    assert_contains "--list shows snapshot 0003" "$output" "[0003]"
    assert_contains "--list shows word count" "$output" "words"
    assert_contains "--list marks current" "$output" "<- current"

    _cleanup_session
    trap - EXIT
}

# Test 5: --jump 2 from snapshot 4
test_jump_to_snapshot() {
    _create_session_with_snapshots 4
    trap '_cleanup_session' EXIT

    "$WP_UNDO" --jump 2
    local seq
    seq=$(wp_seq)

    assert_eq "--jump 2 from snapshot 4" "2" "$seq"

    _cleanup_session
    trap - EXIT
}

# Test 6: --jump to non-existent snapshot
test_jump_nonexistent() {
    _create_session_with_snapshots 3
    trap '_cleanup_session' EXIT

    local output
    local exit_code
    output=$("$WP_UNDO" --jump 99 2>&1)
    exit_code=$?

    assert_exit_code "--jump to non-existent exits with code 1" 1 "$exit_code"

    # Verify seq unchanged
    local seq
    seq=$(wp_seq)
    assert_eq "--jump to non-existent leaves seq unchanged" "3" "$seq"

    _cleanup_session
    trap - EXIT
}

# Test 7: --diff 1 between two known snapshots
test_diff_snapshots() {
    _create_session_with_snapshots 3
    trap '_cleanup_session' EXIT

    local output
    output=$("$WP_UNDO" --diff 1 2>&1)

    assert_contains "--diff shows diff markers" "$output" "Snapshot"

    _cleanup_session
    trap - EXIT
}

# Run tests
test_step_back_once
test_step_back_two
test_step_back_from_oldest
test_list_history
test_jump_to_snapshot
test_jump_nonexistent
test_diff_snapshots

report