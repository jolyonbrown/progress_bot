#!/bin/bash

# This script posts to Bluesky using the AT Protocol API
# It reads the post content from progress_update.txt

# Load environment variables from .env file
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Check if required credentials are set
if [ -z "$BLUESKY_HANDLE" ] || [ -z "$BLUESKY_APP_PASSWORD" ]; then
    echo "Error: BLUESKY_HANDLE and BLUESKY_APP_PASSWORD environment variables must be set"
    exit 1
fi

# Read the post text from progress_update.txt
if [ ! -f progress_update.txt ]; then
    echo "Error: progress_update.txt file not found"
    exit 1
fi

POST_TEXT=$(cat progress_update.txt)
echo "Post text: $POST_TEXT"

# First, authenticate with Bluesky to get session tokens
echo "Authenticating with Bluesky..."
AUTH_RESPONSE=$(curl -s -X POST "https://bsky.social/xrpc/com.atproto.server.createSession" \
    -H "Content-Type: application/json" \
    -d "{\"identifier\": \"$BLUESKY_HANDLE\", \"password\": \"$BLUESKY_APP_PASSWORD\"}")

# Extract access token from response
ACCESS_TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"accessJwt":"[^"]*' | cut -d'"' -f4)

if [ -z "$ACCESS_TOKEN" ]; then
    echo "Error: Failed to authenticate with Bluesky"
    echo "Response: $AUTH_RESPONSE"
    exit 1
fi

echo "Authentication successful"

# Get the DID (Decentralized Identifier) from the auth response
DID=$(echo "$AUTH_RESPONSE" | grep -o '"did":"[^"]*' | cut -d'"' -f4)

if [ -z "$DID" ]; then
    echo "Error: Failed to get DID from authentication response"
    exit 1
fi

echo "DID: $DID"

# Create the post record with current timestamp
CURRENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

# Escape the post text for JSON
ESCAPED_TEXT=$(echo "$POST_TEXT" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

# Create the post
echo "Creating post..."
POST_RESPONSE=$(curl -s -X POST "https://bsky.social/xrpc/com.atproto.repo.createRecord" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"repo\": \"$DID\",
        \"collection\": \"app.bsky.feed.post\",
        \"record\": {
            \"text\": \"$ESCAPED_TEXT\",
            \"createdAt\": \"$CURRENT_TIME\",
            \"\$type\": \"app.bsky.feed.post\"
        }
    }")

# Check if the post was created successfully
if echo "$POST_RESPONSE" | grep -q '"uri"'; then
    echo "Post created successfully!"
    echo "Response: $POST_RESPONSE"
    exit 0
else
    echo "Failed to create post:"
    echo "Response: $POST_RESPONSE"
    exit 1
fi