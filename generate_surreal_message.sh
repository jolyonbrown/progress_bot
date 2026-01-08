#!/bin/bash

# Generate a surreal message using Anthropic API (Claude Haiku 4.5)
# Usage: ./generate_surreal_message.sh <percentage_complete> <days_remaining> <time_of_day>
# Example: ./generate_surreal_message.sh 15.19 1239 "morning"

set -e

PERCENTAGE=$1
DAYS_REMAINING=$2
TIME_OF_DAY=$3

if [ -z "$ANTHROPIC_API_KEY" ]; then
	echo "Error: ANTHROPIC_API_KEY environment variable is not set" >&2
	echo "#Trump" # Fallback
	exit 1
fi

if [ -z "$PERCENTAGE" ] || [ -z "$DAYS_REMAINING" ] || [ -z "$TIME_OF_DAY" ]; then
	echo "Usage: $0 <percentage_complete> <days_remaining> <time_of_day>" >&2
	echo "#Trump" # Fallback
	exit 1
fi

# Create the prompt for generating a surreal message
# Note: The full post includes ~100 chars of stats + grid, so message must be under 80 chars
PROMPT="Generate a single surreal/absurdist phrase about time, democracy, or politics. STRICT LIMIT: Maximum 60 characters including 1 hashtag. Be weird, darkly funny, psychedelic. Context: Trump presidency ${PERCENTAGE}% done, ${DAYS_REMAINING} days left, ${TIME_OF_DAY}. Examples: 'Democracy dissolves like sugar in rain #TimeGoo' or 'The calendar weeps backwards #TemporalPolitics'. Output ONLY the message, nothing else."

# Make API call to Anthropic
RESPONSE=$(curl -s -X POST "https://api.anthropic.com/v1/messages" \
	-H "x-api-key: $ANTHROPIC_API_KEY" \
	-H "anthropic-version: 2023-06-01" \
	-H "Content-Type: application/json" \
	-d "{
        \"model\": \"claude-haiku-4-5-20251001\",
        \"max_tokens\": 50,
        \"messages\": [
            {
                \"role\": \"user\",
                \"content\": \"$PROMPT\"
            }
        ]
    }")

# Extract the message from the JSON response
MESSAGE=$(echo "$RESPONSE" | jq -r '.content[0].text' 2>/dev/null)

# Check if we got a valid response
if [ "$MESSAGE" = "null" ] || [ -z "$MESSAGE" ]; then
	echo "Error: Failed to generate message. API response: $RESPONSE" >&2
	echo "#Trump" # Fallback
	exit 1
fi

# Clean up the message (remove any quotes and trim whitespace)
MESSAGE=$(echo "$MESSAGE" | sed 's/^"//; s/"$//; s/^[[:space:]]*//; s/[[:space:]]*$//; s/["'"'"']$//; s/^["'"'"']//')

echo "$MESSAGE"
