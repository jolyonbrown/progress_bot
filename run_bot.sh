#!/bin/bash
# Script to run the presidential term progress bot with external Bluesky posting script

# Check if .env file exists and source it
if [ -f .env ]; then
    echo "Loading credentials from .env file..."
    # Use set -a to automatically export all variables
    set -a
    source .env
    set +a
    # Explicitly export for child processes
    export BLUESKY_HANDLE
    export BLUESKY_APP_PASSWORD  
    export GROQ_API_KEY
    
    # Print environment variables (redacted for security)
    echo "Environment variables after loading .env:"
    echo "BLUESKY_HANDLE set: $([ ! -z "$BLUESKY_HANDLE" ] && echo "YES" || echo "NO")"
    echo "BLUESKY_APP_PASSWORD set: $([ ! -z "$BLUESKY_APP_PASSWORD" ] && echo "YES" || echo "NO")"
    echo "GROQ_API_KEY set: $([ ! -z "$GROQ_API_KEY" ] && echo "YES" || echo "NO")"
else
    echo "No .env file found. The bot will run without Bluesky API credentials."
    echo "Progress information will be generated locally only."
fi

# Make sure the post_bluesky.sh script is executable
if [ -f post_bluesky.sh ]; then
    chmod +x post_bluesky.sh
    echo "Made post_bluesky.sh executable"
fi

# Run the bot
echo "Running Presidential Term Progress Bot..."
zig build run

# Capture exit status
EXIT_STATUS=$?

# Display the progress update file if it exists
if [ -f progress_update.txt ]; then
    echo ""
    echo "Progress update (from progress_update.txt):"
    cat progress_update.txt
    echo ""
fi

# Exit with the same status as the bot
exit $EXIT_STATUS 