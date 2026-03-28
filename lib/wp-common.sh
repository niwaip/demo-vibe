#!/usr/bin/env bash
# wp-common.sh - Shared library for WP (Writing Pipeline)
# All functions are prefixed with wp_

# wp_session_dir - Prints the absolute path to the active session directory
# Session dir is $WP_SESSION if set, otherwise ./session
# Does not create the directory
wp_session_dir() {
    if [[ -n "${WP_SESSION:-}" ]]; then
        echo "$WP_SESSION"
    else
        echo "./session"
    fi
}

# wp_current - Prints the resolved path of session/current (the active snapshot file)
# Exits with error code 1 and a message to stderr if session/current does not exist
wp_current() {
    local session_dir
    session_dir=$(wp_session_dir)
    local current_file="${session_dir}/current"

    if [[ ! -e "$current_file" ]]; then
        wp_log ERR "No active session. Run 'wp init' first."
        exit 1
    fi

    # Resolve symlink if it is one, otherwise return the path
    if [[ -L "$current_file" ]]; then
        readlink -f "$current_file"
    else
        echo "$current_file"
    fi
}

# wp_commit - Reads stdin, writes it to the next numbered snapshot in session/history/
# Snapshot filenames are zero-padded to 4 digits: 0001.txt, 0002.txt, etc.
# Updates session/current symlink to point to the new snapshot
# Increments the sequence counter stored in session/meta
wp_commit() {
    local session_dir
    session_dir=$(wp_session_dir)
    local history_dir="${session_dir}/history"
    local meta_file="${session_dir}/meta"
    local current_link="${session_dir}/current"

    # Ensure history directory exists
    mkdir -p "$history_dir"

    # Get current sequence number (default to 0 if meta doesn't exist)
    local seq=0
    if [[ -f "$meta_file" ]]; then
        seq=$(grep '^seq=' "$meta_file" | cut -d'=' -f2)
        # Remove leading zeros
        seq=$((10#$seq))
    fi

    # Increment sequence
    local new_seq=$((seq + 1))
    local new_seq_padded
    new_seq_padded=$(printf '%04d' "$new_seq")

    # Write stdin to new snapshot
    local snapshot_file="${history_dir}/${new_seq_padded}.txt"
    cat > "$snapshot_file"

    # Update current symlink
    rm -f "$current_link"
    ln -s "$snapshot_file" "$current_link"

    # Update meta file
    if [[ -f "$meta_file" ]]; then
        # Update seq line
        sed -i "s/^seq=.*/seq=${new_seq_padded}/" "$meta_file"
    else
        echo "seq=${new_seq_padded}" > "$meta_file"
    fi
}

# wp_seq - Prints the current sequence number as a plain integer (e.g. 3)
wp_seq() {
    local session_dir
    session_dir=$(wp_session_dir)
    local meta_file="${session_dir}/meta"

    if [[ ! -f "$meta_file" ]]; then
        echo "0"
        return
    fi

    local seq
    seq=$(grep '^seq=' "$meta_file" | cut -d'=' -f2)
    # Remove leading zeros and print
    echo $((10#$seq))
}

# wp_log - Usage: wp_log LEVEL "message"
# LEVEL is one of: INFO, WARN, ERR
# Writes to stderr only, never stdout (stdout is reserved for filter output)
# Colorize output using ANSI codes: INFO=green, WARN=yellow, ERR=red
# Format: [LEVEL] message
wp_log() {
    local level="$1"
    local message="$2"

    local color_reset='\033[0m'
    local color_red='\033[0;31m'
    local color_green='\033[0;32m'
    local color_yellow='\033[0;33m'

    local color
    case "$level" in
        INFO)
            color="$color_green"
            ;;
        WARN)
            color="$color_yellow"
            ;;
        ERR)
            color="$color_red"
            ;;
        *)
            color="$color_reset"
            ;;
    esac

    echo -e "${color}[${level}]${color_reset} ${message}" >&2
}

# wp_require_cmd - Usage: wp_require_cmd cmd1 cmd2 ...
# For each argument, checks that the command exists via command -v
# If any are missing, prints an ERR log and exits with code 127
wp_require_cmd() {
    local missing=0
    for cmd in "$@"; do
        if ! command -v "$cmd" &> /dev/null; then
            wp_log ERR "Required command not found: ${cmd}"
            missing=1
        fi
    done

    if [[ $missing -eq 1 ]]; then
        exit 127
    fi
}

# wp_escape_sed - Usage: wp_escape_sed "some/string.with[special]chars"
# Prints the string with /, ., [, ], *, ^, $, \ escaped for use in a sed expression
wp_escape_sed() {
    local str="$1"
    # Escape backslash first, then other special characters
    str="${str//\\/\\\\}"
    str="${str//\//\\/}"
    str="${str//./\\.}"
    str="${str//\[/\\[}"
    str="${str//\]/\\]}"
    str="${str//\*/\\*}"
    str="${str//^/\\^}"
    str="${str//\$/\\$}"
    echo "$str"
}