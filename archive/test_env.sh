#!/bin/bash
# Script to directly test environment variables

echo "Testing environment variables directly..."

# Create a simple test program
cat > test_env.zig << 'EOF'
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const var_name = "TWITTER_BEARER_TOKEN";
    const value = std.process.getEnvVarOwned(allocator, var_name) catch |err| {
        std.debug.print("Error getting {s}: {s}\n", .{var_name, @errorName(err)});
        return;
    };
    defer allocator.free(value);

    std.debug.print("{s} = {s}\n", .{var_name, value});
}
EOF

# Compile the test program
echo "Compiling test program..."
zig build-exe test_env.zig

# Test with direct environment variable
echo "Testing with direct environment variable..."
export TEST_VAR="test_value"
./test_env

# Test with .env file
echo "Testing with .env file..."
if [ -f .env ]; then
    echo "Loading .env file..."
    source .env
    
    # Print the value of TWITTER_BEARER_TOKEN (without revealing it)
    if [ -n "$TWITTER_BEARER_TOKEN" ]; then
        echo "TWITTER_BEARER_TOKEN is set in the shell"
        echo "First few characters: ${TWITTER_BEARER_TOKEN:0:5}..."
        echo "Length: ${#TWITTER_BEARER_TOKEN} characters"
    else
        echo "TWITTER_BEARER_TOKEN is NOT set in the shell"
    fi
    
    # Run the test program
    ./test_env
else
    echo "No .env file found"
fi

# Clean up
rm -f test_env test_env.zig

echo "Test complete" 