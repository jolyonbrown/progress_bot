# Presidential Term Progress Bot

A Bluesky bot that calculates how long the current US presidency has to run in terms of days and provides updates with a visual progress grid.

## Features

- Calculates the percentage of the presidential term that has elapsed
- Generates a GitHub-style emoji progress grid (4x12 months)
- Auto-generates surreal daily messages using Groq AI (with fallback)
- Posts directly to Bluesky using AT Protocol API
- Fully automated posting via GitHub Actions (twice daily at 9 AM & 6 PM UTC)

## Prerequisites

- Zig compiler (tested with version 0.11.0 or later)
- Bash shell
- curl (for HTTP requests to Bluesky and Groq APIs)
- jq (for JSON parsing in scripts)
- Bluesky account with App Password
- Groq account with API key (optional, for AI-generated messages)

## Installation

### Building the Bot

1. Clone this repository
2. Build the bot:
   ```
   zig build
   ```

## Setup

1. Set up your Bluesky account:
   - Create a Bluesky account at [bsky.app](https://bsky.app)
   - Go to Settings → App Passwords
   - Generate a new App Password for this bot
   - Save your handle and app password securely

2. Set up your API credentials using a `.env` file:
   - Copy the `.env.example` file to `.env`
   - Fill in your credentials in the `.env` file:
   ```
   BLUESKY_HANDLE=your_handle.bsky.social
   BLUESKY_APP_PASSWORD=your_app_password
   GROQ_API_KEY=your_groq_api_key
   ```

3. Set up your Groq account (optional but recommended):
   - Sign up at [Groq Console](https://console.groq.com/)
   - Generate an API key in your dashboard
   - Add it to your `.env` file as shown above
   - Without this key, the bot will use a simple fallback message

## Usage

Run the bot with:

```
./run_bot.sh
```

This will:
1. Load your API credentials from the `.env` file
2. Calculate the current progress of the presidential term
3. Generate a GitHub-style emoji progress grid
4. Generate a surreal message using Groq AI (or use fallback)
5. Save the progress information to `progress_update.txt`
6. Ask if you want to post to Bluesky

If you choose to post to Bluesky, the script will:
1. Authenticate with Bluesky using your App Password
2. Create a post using the AT Protocol API
3. Handle any errors or duplicate content issues

## How It Works

### Core Components

1. **Zig Application (`src/main.zig`)**:
   - Calculates the presidential term progress (Jan 20, 2025 - Jan 20, 2029)
   - Generates the emoji grid visualization (4 years × 12 months)
   - Calls Groq API to generate contextual surreal messages
   - Saves the progress to a file
   - Calls the posting script if requested

2. **Posting Script (`post_bluesky.sh`)**:
   - Authenticates with Bluesky using AT Protocol
   - Creates session tokens via `com.atproto.server.createSession`
   - Posts content using `com.atproto.repo.createRecord`
   - Handles errors and API responses

3. **AI Message Generator (`generate_surreal_message.sh`)**:
   - Uses Groq's fast LLM inference to generate contextual surreal messages
   - Takes percentage, days remaining, and time of day as context
   - Falls back to simple hashtag if API unavailable
   - Generates darkly humorous, absurdist commentary

### Bluesky AT Protocol Integration

The bot uses the AT Protocol (Authenticated Transfer Protocol) for posting to Bluesky:

1. Authenticates with handle and App Password to get session tokens
2. Uses the access JWT token for authenticated requests
3. Creates post records with proper timestamps and formatting
4. Handles the decentralized nature of the AT Protocol

### AI-Generated Surreal Messages

The bot uses Groq's fast inference API to generate contextual surreal messages:

1. **Dynamic Content**: Each post includes a unique AI-generated surreal message
2. **Context Awareness**: The AI considers percentage complete, days remaining, and time of day
3. **Tone Control**: Prompts guide the AI to create darkly humorous, absurdist political commentary
4. **Fallback Safety**: If Groq API is unavailable, falls back to simple hashtag
5. **Cost Effective**: Uses Groq's efficient LLM inference for minimal API costs

Example AI-generated messages:
- "The democracy hourglass leaks sand made of tweets #TimeIsFlat"
- "In the quantum realm, presidential terms exist in superposition #SchroedingersPOTUS"
- "The calendar pages turn like slow-motion confetti at a funeral #TemporalPolitics"

## Securely Managing Credentials

When using this bot with GitHub or other public repositories, it's important to keep your API credentials secure:

### Using a .env File (Not Included in Git)

Create a `.env` file with your credentials:

```
# IMPORTANT: Do not use quotes or spaces around equals signs
BLUESKY_HANDLE=your_handle.bsky.social
BLUESKY_APP_PASSWORD=your_app_password
GROQ_API_KEY=your_groq_api_key
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

If you encounter authentication issues when trying to post to Bluesky, here are some steps to troubleshoot:

1. **Check your Bluesky credentials**:
   - Ensure that your Bluesky handle and App Password are correct
   - Make sure your handle includes the full domain (e.g., `username.bsky.social`)
   - Verify that your App Password is active and hasn't been revoked

2. **Common Error Messages**:
   - `401 Unauthorized`: Usually indicates incorrect handle or App Password
   - `403 Forbidden`: May indicate rate limiting or account restrictions
   - Connection errors: Check your internet connection and Bluesky service status

3. **App Password Issues**:
   - App Passwords are different from your regular account password
   - Generate a new App Password in Bluesky Settings → App Passwords
   - Each App Password should be unique for different applications

4. **Rate Limits**:
   - Bluesky has rate limits to prevent spam
   - If posting fails due to rate limits, wait a few minutes and try again

If you continue to experience issues, check the [Bluesky Support](https://blueskyweb.xyz/support) or regenerate your App Password.

## License

See the LICENSE file for details. 