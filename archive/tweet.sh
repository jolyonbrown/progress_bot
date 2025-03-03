#!/bin/bash

# Load environment variables from .env file
export $(grep -v '^#' .env | xargs)

# Read the tweet content from progress_update.txt
TWEET_TEXT=$(cat progress_update.txt)
echo "Tweet text: $TWEET_TEXT"

# Generate OAuth parameters
OAUTH_NONCE=$(openssl rand -hex 16)
OAUTH_TIMESTAMP=$(date +%s)
OAUTH_SIGNATURE_METHOD="HMAC-SHA1"
OAUTH_VERSION="1.0"

# URL encode the tweet text for the JSON payload
ENCODED_TWEET_TEXT_JSON=$(echo -n "$TWEET_TEXT" | perl -MURI::Escape -ne 'print uri_escape($_)')

# Create the JSON payload
JSON_PAYLOAD="{\"text\":\"$TWEET_TEXT\"}"
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
curl -v -X POST "$URL" \
  -H "Authorization: $AUTH_HEADER" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD"

echo
echo "Tweet posted!" 