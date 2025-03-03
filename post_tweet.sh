#!/bin/bash

# This script posts a tweet using the Twitter API v2
# It reads the tweet content from progress_update.txt

# Load environment variables from .env file
export $(grep -v '^#' .env | xargs)

# Read the tweet text from progress_update.txt
TWEET_TEXT=$(cat progress_update.txt)
echo "Tweet text: $TWEET_TEXT"

# Generate OAuth parameters
OAUTH_NONCE=$(openssl rand -hex 16)
OAUTH_TIMESTAMP=$(date +%s)
OAUTH_SIGNATURE_METHOD="HMAC-SHA1"
OAUTH_VERSION="1.0"

# Create the JSON payload with properly escaped newlines
JSON_PAYLOAD=$(echo -n "{\"text\":\"$(echo "$TWEET_TEXT" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')\"}")
echo "JSON payload: $JSON_PAYLOAD"

# URL for Twitter API v2
URL="https://api.twitter.com/2/tweets"

# Create parameter string (no status parameter for v2 API)
PARAM_STRING="oauth_consumer_key=$TWITTER_API_KEY&oauth_nonce=$OAUTH_NONCE&oauth_signature_method=$OAUTH_SIGNATURE_METHOD&oauth_timestamp=$OAUTH_TIMESTAMP&oauth_token=$TWITTER_ACCESS_TOKEN&oauth_version=$OAUTH_VERSION"

# Sort the parameters
SORTED_PARAM_STRING=$(echo $PARAM_STRING | tr '&' '\n' | sort | tr '\n' '&' | sed 's/&$//')

# URL encode the parameter string
ENCODED_PARAM_STRING=$(echo -n "$SORTED_PARAM_STRING" | perl -MURI::Escape -ne 'print uri_escape($_)')

# Create the base string
ENCODED_URL=$(echo -n "$URL" | perl -MURI::Escape -ne 'print uri_escape($_)')
BASE_STRING="POST&$ENCODED_URL&$ENCODED_PARAM_STRING"

echo "Base string: $BASE_STRING"

# Create the signing key
SIGNING_KEY="${TWITTER_API_SECRET}&${TWITTER_ACCESS_SECRET}"

# Generate the signature
SIGNATURE=$(echo -n "$BASE_STRING" | openssl dgst -sha1 -hmac "$SIGNING_KEY" -binary | base64)
ENCODED_SIGNATURE=$(echo -n "$SIGNATURE" | perl -MURI::Escape -ne 'print uri_escape($_)')

# Create the Authorization header
AUTH_HEADER="OAuth oauth_consumer_key=\"$TWITTER_API_KEY\", oauth_nonce=\"$OAUTH_NONCE\", oauth_signature=\"$ENCODED_SIGNATURE\", oauth_signature_method=\"$OAUTH_SIGNATURE_METHOD\", oauth_timestamp=\"$OAUTH_TIMESTAMP\", oauth_token=\"$TWITTER_ACCESS_TOKEN\", oauth_version=\"$OAUTH_VERSION\""

echo "Authorization header: $AUTH_HEADER"

# Make the request
RESPONSE=$(curl -s -X POST "$URL" \
  -H "Authorization: $AUTH_HEADER" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD")

# Check if the tweet was posted successfully
if echo "$RESPONSE" | grep -q "id"; then
  echo "Tweet posted successfully!"
  echo "$RESPONSE"
  exit 0
elif echo "$RESPONSE" | grep -q "duplicate content"; then
  echo "Notice: This tweet has already been posted (duplicate content)."
  echo "$RESPONSE"
  # Return success code since this is an expected condition
  exit 0
else
  echo "Failed to post tweet:"
  echo "$RESPONSE"
  exit 1
fi 