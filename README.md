# WP - Writing Pipeline

A bash-based writing pipeline tool for managing, transforming, and spell-checking text documents.
WP provides a session-based approach to document editing with full history tracking,
undo capabilities, and a built-in spell-checking pipeline.

**Philosophy:** Simple, transparent, and reversible. Every change is tracked in a numbered
snapshot history, making it easy to review edits, undo mistakes, and see exactly what
happened to your document.

## Prerequisites

| Requirement | Description |
|-------------|-------------|
| Bash 4.0+   | Required for shell scripts |
| Standard Unix tools | `cat`, `sort`, `uniq`, `tr`, `sed`, `grep`, `comm`, `diff`, `wc` |
| No external dependencies | Pure shell implementation |

## Quick Start

```bash
# Initialize a session with your document
wp init draft.txt

# Check for spelling errors
wp pipe | wp-spell

# Fix a misspelled word
wp run wp-search "kittne" "kitten"

# View session status
wp status

# Undo the last change
wp-undo

# Save back to original file
wp save

# Clean up session
wp clean
```

## Tools

### `wp` - Main Dispatcher

The central command for managing writing sessions.

| Command | Description |
|---------|-------------|
| `wp init <file>` | Start a new session from a file |
| `wp save [outfile]` | Save current snapshot to file (default: original filename) |
| `wp run <script> [args]` | Pipe current snapshot through a script and commit result |
| `wp pipe` | Output current snapshot to stdout |
| `wp status` | Show session info (source, snapshot number, word count) |
| `wp clean` | Remove session directory (prompts for confirmation) |

### `wp-search` - Search and Replace

A mutating filter for text substitution.

```bash
wp-search [OPTIONS] PATTERN REPLACEMENT
```

| Option | Description |
|--------|-------------|
| `-i` | Case-insensitive matching |
| `-g` | Replace all occurrences (default) |
| `-n N` | Replace only the Nth occurrence |
| `-r` | Use extended regex (ERE) pattern |
| `-p` | Preview mode: show diff without committing |

### `wp-stats` - Document Statistics

Display various statistics about a document.

```bash
wp-stats [OPTIONS] [FILE]
```

| Option | Description |
|--------|-------------|
| `-w` | Word count (plain integer) |
| `-l` | Line count |
| `-c` | Character count |
| `-s` | Sentence count |
| `-p` | Paragraph count |
| `--freq N` | Top N most frequent non-stopwords |
| `--avg` | Average word length and words per sentence |
| (no options) | Full formatted report |

### `wp-undo` - History Navigation

Navigate backward through snapshot history.

```bash
wp-undo [OPTIONS]
```

| Option | Description |
|--------|-------------|
| (none) | Step back one snapshot |
| `-n N` | Step back N snapshots |
| `--list` | Show full history with timestamps and word counts |
| `--diff N` | Show colored diff between current and N steps back |
| `--jump N` | Jump to snapshot number N |
| `--prune N` | Delete snapshots older than most recent N |

### `wp-spell` - Spell Checker Pipeline

Check documents for misspelled words using the built-in dictionary.

```bash
wp-spell [OPTIONS] [FILE]
```

| Option | Description |
|--------|-------------|
| (none) | Print misspelled words, one per line |
| `-d FILE` | Use alternate dictionary file |
| `-a WORD` | Add WORD to dictionary and exit |
| `--count` | Print only the count of misspelled words |
| `--no-commit` | Force read-only mode |

The spell pipeline:
1. Extract words (`wp-spell-words`)
2. Normalize to lowercase (`wp-spell-lower`)
3. Sort alphabetically
4. Remove duplicates (`wp-spell-unique`)
5. Filter against dictionary (`wp-spell-mismatch`)

## Dictionary Maintenance

The dictionary is located at `lib/dictionary.txt` and contains common English words.

### Adding words

```bash
# Add a word permanently
wp-spell -a "myword"

# Or edit the file directly and re-sort
echo "myword" >> lib/dictionary.txt
sort -o lib/dictionary.txt lib/dictionary.txt
```

### Dictionary format

- One word per line
- All lowercase
- Alphabetically sorted (required for `comm` comparison)

## Running Tests

```bash
# Run all tests
make test

# Or run individually
bash tests/test-foundation.sh
bash tests/test-spell-integration.sh
bash tests/test-e2e.sh
```

## Project Structure

```
.
├── bin/
│   ├── wp              # Main dispatcher
│   ├── wp-search       # Search/replace tool
│   ├── wp-stats        # Statistics tool
│   ├── wp-undo         # History navigation
│   └── spell/
│       ├── wp-spell          # Spell pipeline assembler
│       ├── wp-spell-words    # Extract words
│       ├── wp-spell-lower    # Normalize case
│       ├── wp-spell-unique   # Remove duplicates
│       └── wp-spell-mismatch # Compare to dictionary
├── lib/
│   ├── wp-common.sh    # Shared library
│   ├── dictionary.txt  # Spell-check dictionary
│   └── stopwords.txt   # Stats stopwords list
├── tests/
│   ├── harness.sh      # Test helper functions
│   ├── test-*.sh       # Various test scripts
│   └── fixtures/       # Test fixtures
├── session/            # Runtime session data (not in git)
├── Makefile
└── README.md
```

## Installation

```bash
make install
# Installs to ~/.local/bin by default
# Override with: make install INSTALL_DIR=/usr/local/bin
``