#!/bin/bash
# Script to run the presidential term progress bot with external Twitter posting script

# Check if .env file exists and source it
if [ -f .env ]; then
    echo "Loading credentials from .env file..."
    # Use set -a to automatically export all variables
    set -a
    source .env
    set +a
    
    # Print environment variables (redacted for security)
    echo "Environment variables after loading .env:"
    echo "TWITTER_API_KEY set: $([ ! -z "$TWITTER_API_KEY" ] && echo "YES" || echo "NO")"
    echo "TWITTER_API_SECRET set: $([ ! -z "$TWITTER_API_SECRET" ] && echo "YES" || echo "NO")"
    echo "TWITTER_ACCESS_TOKEN set: $([ ! -z "$TWITTER_ACCESS_TOKEN" ] && echo "YES" || echo "NO")"
    echo "TWITTER_ACCESS_SECRET set: $([ ! -z "$TWITTER_ACCESS_SECRET" ] && echo "YES" || echo "NO")"
else
    echo "No .env file found. The bot will run without Twitter API credentials."
    echo "Progress information will be generated locally only."
fi

# Make sure the post_tweet.sh script is executable
if [ -f post_tweet.sh ]; then
    chmod +x post_tweet.sh
    echo "Made post_tweet.sh executable"
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