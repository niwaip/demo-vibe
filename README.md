# WP - Writing Pipeline

A bash-based writing pipeline tool for managing and transforming text documents.

## Structure

- `bin/wp` - Main dispatcher script
- `bin/spell/` - Spell checking scripts
- `lib/wp-common.sh` - Shared shell library
- `session/` - Runtime session data (created by `wp init`, not committed)
- `tests/` - Test suite

## Usage

```bash
# Initialize a session with a file
wp init draft.txt

# View session status
wp status

# Run a transformation script
wp run spell

# Save current state
wp save

# Clean up session
wp clean
```

## Testing

```bash
bash tests/test-foundation.sh
```