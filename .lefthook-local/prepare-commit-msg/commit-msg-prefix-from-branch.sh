#!/bin/bash
# Looks at the current branch name and tries to extract the correct work package number from it.
# If found, the commit message will automatically be prefixed with the work package number, following this format:
#
#   [#58160] <your text here>
#

# File path for the commit message
COMMIT_MSG_FILE=$1

# Branch name
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)

# Debugging logs
#echo "Hook triggered for branch: $BRANCH_NAME" >> /tmp/hook_debug.log
#echo "Commit message file: $COMMIT_MSG_FILE" >> /tmp/hook_debug.log

# Extract work package number from branch name (e.g., feature/58160 or bug/59977)
if [[ $BRANCH_NAME =~ (feature|bug)/([0-9]+) ]]; then
    WP_NUMBER=${BASH_REMATCH[2]}
    PREFIX="[#$WP_NUMBER] "
#    echo "Detected issue number: $WP_NUMBER" >> /tmp/hook_debug.log

    # Filter out comment lines and leading whitespace for the check
    FILTERED_MESSAGE=$(grep -v '^#' "$COMMIT_MSG_FILE" | sed 's/^[[:space:]]*//')

    # Log filtered message for debugging
#    echo "Filtered commit message:" >> /tmp/hook_debug.log
#    echo "$FILTERED_MESSAGE" >> /tmp/hook_debug.log

    # Check if the prefix is present in the actual commit message
    if [[ "$FILTERED_MESSAGE" != "$PREFIX"* ]]; then
        echo "$PREFIX$(cat "$COMMIT_MSG_FILE")" > "$COMMIT_MSG_FILE"
    fi
fi
