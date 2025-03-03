#!/bin/bash
# Script to test OAuth 1.0a implementation

echo "OAuth 1.0a Implementation Test"
echo "============================="
echo ""

# Check for required libraries
check_libraries() {
    echo "Checking for required libraries..."
    
    # Check for liboauth
    if ! ldconfig -p | grep -q liboauth; then
        echo "Error: liboauth not found in system libraries."
        echo "Please install it with:"
        echo "  sudo apt-get install liboauth-dev (Ubuntu/Debian)"
        echo "  sudo dnf install liboauth-devel (Fedora)"
        echo "  sudo pacman -S liboauth (Arch)"
        echo "  brew install liboauth (macOS)"
        return 1
    else
        echo "✓ liboauth found"
    fi
    
    # Check for libcurl
    if ! ldconfig -p | grep -q libcurl; then
        echo "Error: libcurl not found in system libraries."
        echo "Please install it with:"
        echo "  sudo apt-get install libcurl4-openssl-dev (Ubuntu/Debian)"
        echo "  sudo dnf install libcurl-devel (Fedora)"
        echo "  sudo pacman -S curl (Arch)"
        echo "  brew install curl (macOS)"
        return 1
    else
        echo "✓ libcurl found"
    fi
    
    return 0
}

# Check for required libraries
if ! check_libraries; then
    echo "Required libraries not found. Please install them and try again."
    exit 1
fi

# Check if .env file exists and source it
if [ -f .env ]; then
    echo "Loading credentials from .env file..."
    # Use set -a to automatically export all variables
    set -a
    source .env
    set +a
    
    # Check if all required credentials are set
    if [ -z "$TWITTER_API_KEY" ] || [ -z "$TWITTER_API_SECRET" ] || [ -z "$TWITTER_ACCESS_TOKEN" ] || [ -z "$TWITTER_ACCESS_SECRET" ]; then
        echo "Error: One or more required OAuth 1.0a credentials are missing."
        echo "Please make sure the following environment variables are set in your .env file:"
        echo "  TWITTER_API_KEY"
        echo "  TWITTER_API_SECRET"
        echo "  TWITTER_ACCESS_TOKEN"
        echo "  TWITTER_ACCESS_SECRET"
        exit 1
    fi
    
    echo "All required OAuth 1.0a credentials are set."
else
    echo "Error: No .env file found. Please create one with your Twitter API credentials."
    exit 1
fi

# Create a simple test program
echo "Creating test program..."
cat > test_oauth.zig << 'EOF'
const std = @import("std");
const oauth = @import("src/oauth.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    std.debug.print("Testing OAuth 1.0a implementation...\n", .{});
    
    // Initialize OAuth credentials
    var credentials = oauth.initCredentialsFromEnv(allocator) catch |err| {
        std.debug.print("Failed to initialize OAuth credentials: {s}\n", .{@errorName(err)});
        return;
    };
    defer oauth.freeCredentials(allocator, credentials);
    
    std.debug.print("OAuth credentials loaded successfully.\n", .{});
    std.debug.print("Consumer key: {s}...\n", .{credentials.consumer_key[0..5]});
    std.debug.print("Access token: {s}...\n", .{credentials.access_token[0..5]});
    
    // Test posting a tweet
    std.debug.print("\nWould you like to post a test tweet? (y/n): ", .{});
    
    const stdin = std.io.getStdIn().reader();
    var buf: [10]u8 = undefined;
    const input = try stdin.readUntilDelimiterOrEof(&buf, '\n');
    
    if (input != null and (input.?[0] == 'y' or input.?[0] == 'Y')) {
        const test_tweet = "This is a test tweet from my Presidential Term Progress Bot using OAuth 1.0a in Zig! " ++ 
                           "Timestamp: " ++ std.fmt.allocPrint(allocator, "{d}", .{std.time.timestamp()}) catch "unknown";
        defer allocator.free(test_tweet);
        
        std.debug.print("Posting test tweet: {s}\n", .{test_tweet});
        
        const response = oauth.postTweet(allocator, credentials, test_tweet) catch |err| {
            std.debug.print("Failed to post tweet: {s}\n", .{@errorName(err)});
            return;
        };
        defer allocator.free(response);
        
        std.debug.print("Tweet posted successfully!\n", .{});
        std.debug.print("Response: {s}\n", .{response});
    } else {
        std.debug.print("Skipping test tweet.\n", .{});
    }
    
    std.debug.print("\nOAuth 1.0a test completed successfully!\n", .{});
}
EOF

# Compile and run the test program
echo "Compiling test program..."
zig build-exe test_oauth.zig -I. -lc -loauth -lcurl

if [ $? -eq 0 ]; then
    echo "Compilation successful. Running test program..."
    ./test_oauth
else
    echo "Compilation failed. Please check the error messages above."
    exit 1
fi

# Clean up
echo "Cleaning up..."
rm -f test_oauth test_oauth.zig

echo "Test completed." 