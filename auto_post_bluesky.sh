#!/bin/bash

# Automated Bluesky posting script
# This script runs the bot and automatically posts to Bluesky without user interaction

set -e  # Exit on any error

echo "=== Automated Presidential Term Progress Bot ==="
echo "Starting at $(date)"

# Load environment variables if .env exists
if [ -f .env ]; then
    echo "Loading credentials from .env file..."
    set -a
    source .env
    set +a
else
    echo "No .env file found. Checking for environment variables..."
fi

# Check if required credentials are set
if [ -z "$BLUESKY_HANDLE" ] || [ -z "$BLUESKY_APP_PASSWORD" ]; then
    echo "Error: BLUESKY_HANDLE and BLUESKY_APP_PASSWORD must be set"
    echo "Either create a .env file or set environment variables"
    exit 1
fi

if [ -z "$GROQ_API_KEY" ]; then
    echo "Warning: GROQ_API_KEY is not set. Surreal messages will use fallback."
fi

echo "Credentials found. Running bot..."

# Make sure scripts are executable
chmod +x post_bluesky.sh generate_surreal_message.sh

# Build and run the bot
echo "Building bot..."
zig build

echo "Generating progress update..."
# Run the Zig application to generate the progress update
echo "n" | zig build run > /dev/null 2>&1 || {
    echo "Running without interactive prompt..."
    zig build run < /dev/null
}

# Check if progress_update.txt was created
if [ ! -f progress_update.txt ]; then
    echo "Error: progress_update.txt was not created"
    exit 1
fi

echo "Progress update generated. Contents:"
cat progress_update.txt

echo ""
echo "Posting to Bluesky..."

# Post to Bluesky
if ./post_bluesky.sh; then
    echo "✅ Successfully posted to Bluesky!"
    echo "Completed at $(date)"
else
    echo "❌ Failed to post to Bluesky"
    exit 1
fi