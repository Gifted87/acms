#!/bin/bash

# ACMS Easy-Spin Script
# Usage: ./acms.sh [PORT] [INSTANCE_NAME]
# Example: ./acms.sh 4001 finance

# 1. Parse Arguments (Defaults: Port 4000, Name "default")
PORT=${1:-4000}
NAME=${2:-default}

# 2. Define Data Directory
# We store data in a "memory_cartridges" folder in the project root for organization,
# but strictly separated by instance name.
DATA_ROOT="./memory_cartridges"
INSTANCE_DATA_DIR="${DATA_ROOT}/${NAME}"

# 3. Export Environment Variables for ACMS (runtime.exs picks these up)
export ACMS_PORT=$PORT
export ACMS_NODE_NAME=$NAME
export ACMS_DATA_DIR=$INSTANCE_DATA_DIR

# 4. Generate a runtime secret if one isn't set (prevents session hijacking between restarts)
# Note: In production persistence, you might want this to be static, but for
# dynamic ephemeral spin-ups, a random secret is safer than a hardcoded one.
if [ -z "$ACMS_SECRET" ]; then
    export ACMS_SECRET=$(openssl rand -base64 32)
fi

# 5. UI Feedback
echo "=================================================="
echo "          ACMS: INSTANCE LAUNCHER                 "
echo "=================================================="
echo "   Instance Name : $NAME"
echo "   Port          : $PORT"
echo "   Memory Path   : $INSTANCE_DATA_DIR"
echo "   OS PID        : $$"
echo "=================================================="

# 6. Ensure Data Directory Exists
mkdir -p "$INSTANCE_DATA_DIR"

# 7. Boot the Server
# We use --name to ensure the Erlang Node has a unique identity.
# This is critical for Mnesia if we ever network them.
# We map 'localhost' assuming local usage.
CMD="elixir --name ${NAME}@127.0.0.1 -S mix phx.server"

echo "Running: $CMD"
print_line() { printf "%0.s-" {1..50}; echo; }
print_line

# Exec replaces the shell process, handling signals correctly
exec $CMD
