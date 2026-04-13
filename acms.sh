#!/bin/bash
# ------------------------------------------------------------------------------
# ACMS Portability Loader (Interactive Mode)
# ------------------------------------------------------------------------------

# 1. Parameter Resolution (Swap handled: If $1 is a number, assume it's the port)
if [[ "$1" =~ ^[0-9]+$ ]]; then
    PORT="$1"
    NAME="${2:-cms}"
else
    NAME="${1:-cms}"
    PORT="${2:-4000}"
fi

export ACMS_NODE_NAME="$NAME"
export ACMS_PORT="$PORT"

# 2. Data Directory Resolution
if [ -z "$ACMS_DATA_DIR" ]; then
    export ACMS_DATA_DIR="$(pwd)/memory_cartridges/${NAME}"
else
    echo "[ACMS] Manual cartridge detected at: $ACMS_DATA_DIR"
fi

mkdir -p "$ACMS_DATA_DIR"

# 3. Environment Setup
export REPLACE_OS_VARS=true
export MIX_ENV=dev

# 4. Identity Construction (THIS WAS MISSING/BROKEN)
# We bind ONLY to loopback to prevent accidental cluster meshes on public LANs
NODE_ID="${NAME}@127.0.0.1"

echo "=================================================="
echo "          ACMS: INSTANCE LAUNCHER                 "
echo "=================================================="
echo " Instance Name : $NAME"
echo " Port          : $PORT"
echo " Node ID       : $NODE_ID"
echo " Memory Path   : $ACMS_DATA_DIR"
echo "=================================================="

# 5. Boot Sequence (Interactive)
# Using 'iex' so it stays alive and gives you a shell
# Cookie is used for secure node-to-node communication
COOKIE="${ACMS_COOKIE:-secure_cognitive_cookie}"
iex --name "$NODE_ID" --cookie "$COOKIE" -S mix
