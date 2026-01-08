# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Building and Running
- `zig build` - Build the project (creates both executable and static library)
- `zig build run` - Build and run the bot directly
- `./run_bot.sh` - Recommended way to run the bot (handles .env file loading and displays output)
- `zig build test` - Run unit tests for both library and executable

### Development
- Test specific functionality: `zig test src/main.zig` or `zig test src/root.zig`
- Check build status: `zig build --help` shows available build steps

## Architecture

This is a Presidential Term Progress Bot that posts Bluesky updates showing the completion percentage of the current US presidential term with a visual emoji progress grid.

### Core Components

**Main Application (`src/main.zig`)**:
- Calculates presidential term progress using hardcoded start/end timestamps (Jan 20, 2025 to Jan 20, 2029)
- Generates GitHub-style progress grid using emoji squares (🟩🟧🟨🟫⬛) representing 4 years × 12 months
- Generates contextual surreal messages using Anthropic API (Claude Haiku 4.5) based on progress and time of day
- Manages Bluesky API credentials from environment variables
- Saves progress output to `progress_update.txt`

**Build System (`build.zig`)**:
- Creates both static library and executable targets
- Links with libc for system functionality
- Supports standard Zig build options (target, optimization)

**Shell Scripts**:
- `run_bot.sh` - Main entry point that sources `.env` file and runs the bot
- `post_bluesky.sh` - AT Protocol implementation for posting to Bluesky
- `generate_surreal_message.sh` - Anthropic API (Claude Haiku 4.5) integration for AI-generated messages
- `auto_post_bluesky.sh` & `install_cron.sh` - Automation scripts for scheduled posting

### Data Flow

1. Bot calculates time-based progress percentage
2. Generates emoji grid visualization (4×12 grid representing months)
3. Calls Anthropic API (Claude Haiku 4.5) to generate contextual surreal message (with fallback)
4. Combines data into post format and saves to `progress_update.txt`
5. If credentials available, uses shell script to post to Bluesky via AT Protocol

### Key Dependencies

- **Environment**: Requires `.env` file with Bluesky and Anthropic API (Claude Haiku 4.5) credentials (not in git)
- **External Tools**: Uses `curl` for HTTP requests and `jq` for JSON processing
- **AI Integration**: Anthropic API (Claude Haiku 4.5) for generating contextual surreal messages (with fallback to hashtag)

### Bluesky Integration

The bot posts twice daily (12:00 and 18:00 UTC) with AI-generated contextual messages. AT Protocol authentication is handled entirely in bash using curl and standard Unix tools rather than Zig libraries. Anthropic API (Claude Haiku 4.5) integration provides fast, cost-effective LLM inference for dynamic message generation.

### Automation

GitHub Actions workflow (`.github/workflows/bot.yml`) runs twice daily at 12:00 and 18:00 UTC, with Ubuntu environment setup including Zig 0.15.1, dependencies, Bluesky and Anthropic API credential handling. Posts are fully automated without user interaction.