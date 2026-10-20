#!/usr/bin/env bash
# Preview page commands by default. --execute opts into reviewed commands.
set -euo pipefail
exec python3 -B "$(dirname "$0")/quickstart_commands.py" "$@"
