# Presidential Term Progress Bot

A Twitter/X.com bot that calculates how long the current US presidency has to run in terms of days and provides updates with a progress bar.

## Features

- Calculates the percentage of the presidential term that has elapsed
- Generates a text-based ASCII progress bar
- Provides updates with the progress information
- Posts directly to Twitter/X using a shell script with OAuth 1.0a

## Prerequisites

- Zig compiler (tested with version 0.11.0 or later)
- Bash shell
- Perl with URI::Escape module (for URL encoding in the posting script)
- OpenSSL (for generating OAuth signatures)
- Twitter/X.com Developer Account (for posting to Twitter)

## Installation

### Building the Bot

1. Clone this repository
2. Build the bot:
   ```
   zig build
   ```

## Setup

1. Set up your Twitter/X.com Developer Account:
   - Go to [Twitter Developer Portal](https://developer.twitter.com/)
   - Sign up for a developer account if you don't have one
   - Create a new Project and App in the developer portal
   - Set up User Authentication Settings:
     - Select "Read and Write" permissions
     - Set the App type to "Web App, Automated App or Bot"
     - Set the callback URL and website URL (can be your GitHub profile)
   - Generate API keys and tokens:
     - Save the API Key and API Key Secret
     - Generate Access Token and Access Token Secret

2. Set up your Twitter API credentials using a `.env` file:
   - Copy the `.env.example` file to `.env`
   - Fill in your credentials in the `.env` file:
   ```
   TWITTER_API_KEY=your_api_key
   TWITTER_API_SECRET=your_api_secret
   TWITTER_ACCESS_TOKEN=your_access_token
   TWITTER_ACCESS_SECRET=your_access_secret
   ```

## Usage

Run the bot with:

```
./run_bot.sh
```

This will:
1. Load your Twitter API credentials from the `.env` file
2. Calculate the current progress of the presidential term
3. Generate a text-based ASCII progress bar
4. Save the progress information to `progress_update.txt`
5. Ask if you want to post to Twitter

If you choose to post to Twitter, the script will:
1. Generate the necessary OAuth 1.0a signature
2. Post the tweet using the Twitter API v2
3. Handle any errors or duplicate content issues

## How It Works

### Core Components

1. **Zig Application (`src/main.zig`)**:
   - Calculates the presidential term progress
   - Generates the ASCII progress bar
   - Saves the progress to a file
   - Calls the posting script if requested

2. **Posting Script (`post_tweet.sh`)**:
   - Implements OAuth 1.0a authentication
   - Handles the Twitter API v2 interaction
   - Posts the tweet with proper error handling

### Twitter API Integration

The bot uses the Twitter API v2 endpoint for posting tweets. The OAuth 1.0a implementation in the shell script:

1. Generates a unique nonce and timestamp
2. Creates the OAuth signature using HMAC-SHA1
3. Constructs the Authorization header
4. Posts the tweet with proper JSON formatting

## Securely Managing Credentials

When using this bot with GitHub or other public repositories, it's important to keep your API credentials secure:

### Using a .env File (Not Included in Git)

Create a `.env` file with your credentials:

```
# IMPORTANT: Do not use quotes or spaces around equals signs
TWITTER_API_KEY=your_api_key
TWITTER_API_SECRET=your_api_secret
TWITTER_ACCESS_TOKEN=your_access_token
TWITTER_ACCESS_SECRET=your_access_secret
```

Make sure to add `.env` to your `.gitignore` file:

```
# Add to .gitignore
.env
```

#### Troubleshooting .env Files

If you're having issues with your `.env` file:

1. Make sure there are no spaces around the equals sign:
   - Correct: `VARIABLE=value`
   - Incorrect: `VARIABLE = value`

2. Do not use quotes around values unless absolutely necessary:
   - Correct: `VARIABLE=value`
   - Incorrect: `VARIABLE="value"`

## Setting up as a Scheduled Task

To run this bot automatically on a schedule:

### Linux (using cron)

1. Edit your crontab:
   ```
   crontab -e
   ```

2. Add a line to run the bot daily at a specific time (e.g., 8 AM):
   ```
   0 8 * * * cd /path/to/progress_bot && ./run_bot.sh
   ```

### Windows (using Task Scheduler)

1. Open Task Scheduler
2. Create a new Basic Task
3. Set the trigger to Daily
4. Set the action to Start a Program
5. Create a batch file that runs the script
6. Point the Task Scheduler to this batch file

## Troubleshooting

### Authentication Issues

If you encounter authentication issues when trying to post to Twitter, here are some steps to troubleshoot:

1. **Check your Twitter API credentials**:
   - Ensure that your Twitter API key, API secret, access token, and access token secret are correct.
   - Verify that your Twitter Developer App has the necessary permissions to post tweets.
   - Make sure your app has "Read and Write" permissions in the Twitter Developer Portal.

2. **Common Error Messages**:
   - `401 Unauthorized` with message `"Could not authenticate you"`: This usually indicates an issue with your OAuth 1.0a credentials or signature generation.
   - `403 Forbidden` with message about "Unsupported Authentication": This indicates you're using the wrong authentication method for the endpoint.
   - `403 Forbidden` with message about "duplicate content": This means you're trying to post the same tweet text again, which Twitter doesn't allow.

3. **API Rate Limits**:
   - Twitter has rate limits on its API. If you exceed these limits, you may receive a `429 Too Many Requests` error.

4. **Check App Status**:
   - Ensure your Twitter Developer App is active and not suspended.

If you continue to experience issues, you may need to regenerate your Twitter API credentials in the Twitter Developer Portal.

## License

See the LICENSE file for details. 