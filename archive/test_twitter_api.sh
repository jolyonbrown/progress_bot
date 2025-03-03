#!/bin/bash
# Script to test Twitter API connectivity and permissions

# Function to URL-decode a string
urldecode() {
    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}

# Load credentials from .env file if it exists
if [ -f .env ]; then
    echo "Loading credentials from .env file..."
    set -a
    source .env
    set +a
    
    # URL-decode the bearer token if it exists
    if [ ! -z "$TWITTER_BEARER_TOKEN" ]; then
        DECODED_TOKEN=$(urldecode "$TWITTER_BEARER_TOKEN")
        echo "Bearer token loaded and decoded"
    else
        echo "Error: TWITTER_BEARER_TOKEN not found in .env file"
        exit 1
    fi
else
    echo "No .env file found. Please create one with your Twitter API credentials."
    exit 1
fi

echo "=== Twitter API Connection Test ==="
echo "This script will test your Twitter API credentials by making simple API calls."
echo ""

# Test 1: Check account information using v2 API
echo "Test 1: Checking account information (v2 API)..."
ACCOUNT_RESPONSE=$(curl -s -X GET "https://api.twitter.com/2/users/me" \
  -H "Authorization: Bearer $DECODED_TOKEN")

echo "Response: $ACCOUNT_RESPONSE"
if echo "$ACCOUNT_RESPONSE" | grep -q "\"data\""; then
    echo "✅ Account information retrieved successfully"
else
    echo "❌ Failed to retrieve account information"
    echo "This may indicate an issue with your bearer token or permissions"
fi
echo ""

# Test 2: Check rate limit status using v1.1 API
echo "Test 2: Checking rate limit status (v1.1 API)..."
RATE_LIMIT_RESPONSE=$(curl -s -X GET "https://api.twitter.com/1.1/application/rate_limit_status.json" \
  -H "Authorization: Bearer $DECODED_TOKEN")

echo "Response: $RATE_LIMIT_RESPONSE"
if echo "$RATE_LIMIT_RESPONSE" | grep -q "\"resources\""; then
    echo "✅ Rate limit information retrieved successfully"
else
    echo "❌ Failed to retrieve rate limit information"
    echo "This may indicate an issue with v1.1 API access"
fi
echo ""

# Test 3: Try to upload a small test image
echo "Test 3: Testing media upload (v1.1 API)..."
# Create a small test image
echo "Creating test image..."
convert -size 100x100 xc:white test_image.png

UPLOAD_RESPONSE=$(curl -s -X POST "https://upload.twitter.com/1.1/media/upload.json" \
  -H "Authorization: Bearer $DECODED_TOKEN" \
  -F "media=@test_image.png")

echo "Response: $UPLOAD_RESPONSE"
if echo "$UPLOAD_RESPONSE" | grep -q "\"media_id\""; then
    echo "✅ Media upload successful"
    # Extract media_id for cleanup
    MEDIA_ID=$(echo "$UPLOAD_RESPONSE" | grep -o '"media_id":[0-9]*' | cut -d':' -f2)
else
    echo "❌ Media upload failed"
    echo "This indicates an issue with media upload permissions"
fi
echo ""

# Test 4: Check if we can post a tweet (without actually posting)
echo "Test 4: Checking tweet posting capability (v2 API)..."
TWEET_CHECK_RESPONSE=$(curl -s -X GET "https://api.twitter.com/2/tweets" \
  -H "Authorization: Bearer $DECODED_TOKEN")

echo "Response: $TWEET_CHECK_RESPONSE"
if echo "$TWEET_CHECK_RESPONSE" | grep -q "\"data\"" || echo "$TWEET_CHECK_RESPONSE" | grep -q "\"meta\""; then
    echo "✅ Tweet endpoint accessible"
else
    echo "❌ Tweet endpoint not accessible"
    echo "This may indicate an issue with write permissions"
fi
echo ""

# Test 5: Try to post a simple text-only tweet (Free tier test)
echo "Test 5: Testing text-only tweet posting (v2 API)..."
# Create a JSON payload for a text-only tweet
echo '{"text": "This is a test tweet from my bot - testing API access"}' > test_tweet.json

TEXT_TWEET_RESPONSE=$(curl -s -X POST "https://api.twitter.com/2/tweets" \
  -H "Authorization: Bearer $DECODED_TOKEN" \
  -H "Content-Type: application/json" \
  -d @test_tweet.json)

echo "Response: $TEXT_TWEET_RESPONSE"
if echo "$TEXT_TWEET_RESPONSE" | grep -q "\"data\""; then
    echo "✅ Text-only tweet posting successful"
    echo "You can post text-only tweets even on the Free tier"
else
    echo "❌ Text-only tweet posting failed"
    echo "This indicates your Free tier may not allow posting tweets at all"
fi
echo ""

# Test 6: Check available endpoints for Free tier
echo "Test 6: Checking available endpoints for Free tier..."
ENDPOINTS_RESPONSE=$(curl -s -X GET "https://api.twitter.com/2/openapi.json" \
  -H "Authorization: Bearer $DECODED_TOKEN")

echo "Checking which endpoints are available on your tier..."
if echo "$ENDPOINTS_RESPONSE" | grep -q "paths"; then
    echo "✅ OpenAPI specification retrieved"
    echo "Endpoints that might be available on Free tier:"
    echo "$ENDPOINTS_RESPONSE" | grep -o '"/2/[^"]*"' | sort | uniq
else
    echo "❌ Could not retrieve OpenAPI specification"
fi
echo ""

# Clean up
echo "Cleaning up..."
rm -f test_image.png test_tweet.json

echo "=== Test Summary ==="
echo "If media upload failed but text-only tweets work, you can:"
echo "1. Modify your bot to post text-only updates"
echo "2. Use ASCII art for a text-based progress bar"
echo "3. Host images elsewhere and include links in your tweets"
echo ""
echo "Free tier limitations are significant. Consider:"
echo "1. Using only the endpoints that worked in the tests above"
echo "2. Upgrading to a paid tier if media upload is essential"
echo ""
echo "For more information, visit: https://developer.twitter.com/en/docs/twitter-api" 