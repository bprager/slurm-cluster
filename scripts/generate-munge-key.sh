#!/bin/bash

# Generate a munge key for the cluster
# This key must be shared across all nodes for authentication

MUNGE_KEY_FILE="./shared/munge.key"

echo "Generating munge key..."

# Create a random 1024-bit key
dd if=/dev/urandom bs=1 count=1024 > "$MUNGE_KEY_FILE" 2>/dev/null

# Set proper permissions
chmod 400 "$MUNGE_KEY_FILE"

echo "Munge key generated at: $MUNGE_KEY_FILE"
echo "This key must be copied to all nodes in the cluster."
echo "File permissions must be 400 and owned by the munge user."
