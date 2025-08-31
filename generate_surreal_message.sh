#!/bin/bash

# Generate a surreal message using Groq API
# Usage: ./generate_surreal_message.sh <percentage_complete> <days_remaining> <time_of_day>
# Example: ./generate_surreal_message.sh 15.19 1239 "morning"

set -e

PERCENTAGE=$1
DAYS_REMAINING=$2
TIME_OF_DAY=$3

if [ -z "$GROQ_API_KEY" ]; then
	echo "Error: GROQ_API_KEY environment variable is not set" >&2
	echo "#Trump" # Fallback
	exit 1
fi

if [ -z "$PERCENTAGE" ] || [ -z "$DAYS_REMAINING" ] || [ -z "$TIME_OF_DAY" ]; then
	echo "Usage: $0 <percentage_complete> <days_remaining> <time_of_day>" >&2
	echo "#Trump" # Fallback
	exit 1
fi

# Create the prompt for generating a surreal message
PROMPT="You are a surreal, wildly absurdist social media bot commenting on the Trump presidency progress. The presidency is ${PERCENTAGE}% complete with ${DAYS_REMAINING} days remaining. It's ${TIME_OF_DAY} time. Generate a single, short (under 50 words), darkly humorous or surreal comment about the passage of time, democracy, or the political situation. Be creative, highly absurd, but not offensive. Think psychedelic imagery. Include relevant hashtags. Examples: 'The democracy hourglass leaks sand made of tweets #TimeIsFlat' or 'In the quantum realm, presidential terms exist in superposition #SchroedingersPOTUS'. Generate only the message, no quotes or explanations. Do not include the current year in output"

# Escape the prompt for JSON
ESCAPED_PROMPT=$(echo "$PROMPT" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

# Make API call to Groq
RESPONSE=$(curl -s -X POST "https://api.groq.com/openai/v1/chat/completions" \
	-H "Authorization: Bearer $GROQ_API_KEY" \
	-H "Content-Type: application/json" \
	-d "{
        \"model\": \"llama-3.1-8b-instant\",
        \"messages\": [
            {
                \"role\": \"user\",
                \"content\": \"$ESCAPED_PROMPT\"
            }
        ],
        \"max_tokens\": 100,
        \"temperature\": 0.8
    }")

# Extract the message from the JSON response
MESSAGE=$(echo "$RESPONSE" | jq -r '.choices[0].message.content' 2>/dev/null)

# Check if we got a valid response
if [ "$MESSAGE" = "null" ] || [ -z "$MESSAGE" ]; then
	echo "Error: Failed to generate message. API response: $RESPONSE" >&2
	echo "#Trump" # Fallback
	exit 1
fi

# Clean up the message (remove any quotes and trim whitespace)
MESSAGE=$(echo "$MESSAGE" | sed 's/^"//; s/"$//; s/^[[:space:]]*//; s/[[:space:]]*$//; s/["'"'"']$//; s/^["'"'"']//')

echo "$MESSAGE"

