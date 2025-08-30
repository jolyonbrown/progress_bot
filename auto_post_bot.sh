#!/bin/bash
# Script to run the presidential term progress bot with automatic posting to Twitter

# Set the working directory to the script's directory
cd "$(dirname "$0")"

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
	exit 1
fi

# Make sure the post_tweet.sh script is executable
if [ -f post_tweet.sh ]; then
	chmod +x post_tweet.sh
	echo "Made post_tweet.sh executable"
fi

# Run the bot and automatically answer "y" to the posting prompt
echo "Running Presidential Term Progress Bot with automatic posting..."
echo "y" | /home/jolyon/zig/zig-linux-x86_64-0.14.0-dev.1767+d23db9427/zig build run

# Capture exit status
EXIT_STATUS=$?

# Log the result
timestamp=$(date "+%Y-%m-%d %H:%M:%S")
if [ $EXIT_STATUS -eq 0 ]; then
	echo "[$timestamp] Bot ran successfully and posted to Twitter" >>bot_log.txt
else
	echo "[$timestamp] Bot failed with exit code $EXIT_STATUS" >>bot_log.txt
fi

# Exit with the same status as the bot
exit $EXIT_STATUS

