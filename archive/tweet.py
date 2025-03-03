#!/usr/bin/env python3
import os
import requests
import hmac
import hashlib
import base64
import urllib.parse
import time
import uuid
import json

# Load credentials from .env file
with open('.env', 'r') as f:
    for line in f:
        key, value = line.strip().split('=', 1)
        os.environ[key] = value

# Twitter API credentials
consumer_key = os.environ['TWITTER_API_KEY']
consumer_secret = os.environ['TWITTER_API_SECRET']
access_token = os.environ['TWITTER_ACCESS_TOKEN']
access_token_secret = os.environ['TWITTER_ACCESS_SECRET']

# Read the tweet content from progress_update.txt
with open('progress_update.txt', 'r') as f:
    tweet_text = f.read().strip()

# Twitter API endpoint for posting tweets
url = 'https://api.twitter.com/1.1/statuses/update.json'

# Generate OAuth parameters
oauth_nonce = uuid.uuid4().hex
oauth_timestamp = str(int(time.time()))
oauth_signature_method = 'HMAC-SHA1'
oauth_version = '1.0'

# Create parameter string
params = {
    'status': tweet_text,
    'oauth_consumer_key': consumer_key,
    'oauth_nonce': oauth_nonce,
    'oauth_signature_method': oauth_signature_method,
    'oauth_timestamp': oauth_timestamp,
    'oauth_token': access_token,
    'oauth_version': oauth_version
}

# Create the base string
param_string = '&'.join([f"{urllib.parse.quote(k)}={urllib.parse.quote(str(v))}" for k, v in sorted(params.items())])
base_string = f"POST&{urllib.parse.quote(url)}&{urllib.parse.quote(param_string)}"

# Create the signing key
signing_key = f"{urllib.parse.quote(consumer_secret)}&{urllib.parse.quote(access_token_secret)}"

# Generate the signature
signature = base64.b64encode(
    hmac.new(
        signing_key.encode('utf-8'),
        base_string.encode('utf-8'),
        hashlib.sha1
    ).digest()
).decode('utf-8')

# Add the signature to the parameters
params['oauth_signature'] = signature

# Create the Authorization header
auth_header = 'OAuth ' + ', '.join([f'{urllib.parse.quote(k)}="{urllib.parse.quote(str(v))}"' for k, v in sorted(params.items()) if k.startswith('oauth_')])

# Print debug information
print(f"URL: {url}")
print(f"Tweet text: {tweet_text}")
print(f"Base string: {base_string}")
print(f"Authorization header: {auth_header}")

# Make the request
headers = {
    'Authorization': auth_header,
    'Content-Type': 'application/x-www-form-urlencoded'
}

response = requests.post(url, data={'status': tweet_text}, headers=headers)

# Print the response
print(f"Status code: {response.status_code}")
print(f"Response: {response.text}")

if response.status_code == 200:
    print("Tweet posted successfully!")
else:
    print("Failed to post tweet.") 