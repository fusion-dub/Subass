#!/bin/zsh

# Move to the script's directory (already the project root)
cd "$(dirname "$0")"

# Run the project's installer script
/bin/zsh "install/_m.sh"
