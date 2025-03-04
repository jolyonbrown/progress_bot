// Presidential Term Progress Bot
// Calculates how long the current US presidency has to run and provides updates with a progress bar.

// date -d "2025-01-20 17:00:00 UTC" +%s
// 1737392400
// date -d "2029-01-20 17:00:00 UTC" +%s
// 1863622800

const std = @import("std");

// Twitter API credentials will be loaded from environment variables
// Set these before running the program:
// export TWITTER_API_KEY="your_api_key"
// export TWITTER_API_SECRET="your_api_secret"
// export TWITTER_ACCESS_TOKEN="your_access_token"
// export TWITTER_ACCESS_SECRET="your_access_secret"

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // Load Twitter API credentials from environment variables
    std.debug.print("Loading Twitter API credentials from environment variables...\n", .{});
    
    const api_key = std.process.getEnvVarOwned(allocator, "TWITTER_API_KEY") catch |err| blk: {
        std.debug.print("Failed to get TWITTER_API_KEY: {s}\n", .{@errorName(err)});
        break :blk null;
    };
    const api_secret = std.process.getEnvVarOwned(allocator, "TWITTER_API_SECRET") catch |err| blk: {
        std.debug.print("Failed to get TWITTER_API_SECRET: {s}\n", .{@errorName(err)});
        break :blk null;
    };
    const access_token = std.process.getEnvVarOwned(allocator, "TWITTER_ACCESS_TOKEN") catch |err| blk: {
        std.debug.print("Failed to get TWITTER_ACCESS_TOKEN: {s}\n", .{@errorName(err)});
        break :blk null;
    };
    const access_secret = std.process.getEnvVarOwned(allocator, "TWITTER_ACCESS_SECRET") catch |err| blk: {
        std.debug.print("Failed to get TWITTER_ACCESS_SECRET: {s}\n", .{@errorName(err)});
        break :blk null;
    };
    
    defer if (api_key) |v| allocator.free(v);
    defer if (api_secret) |v| allocator.free(v);
    defer if (access_token) |v| allocator.free(v);
    defer if (access_secret) |v| allocator.free(v);

    // Print status of environment variables
    std.debug.print("Environment variables status:\n", .{});
    std.debug.print("  TWITTER_API_KEY: {s}\n", .{if (api_key != null) "Set" else "Not set"});
    std.debug.print("  TWITTER_API_SECRET: {s}\n", .{if (api_secret != null) "Set" else "Not set"});
    std.debug.print("  TWITTER_ACCESS_TOKEN: {s}\n", .{if (access_token != null) "Set" else "Not set"});
    std.debug.print("  TWITTER_ACCESS_SECRET: {s}\n", .{if (access_secret != null) "Set" else "Not set"});

    const START_OF_TERM: i64 = 1737354000; // Jan 20, 2025, 12:00 PM ET (UTC)
    const END_OF_TERM: i64 = 1863622800; // Jan 20, 2029, 12:00 PM ET (UTC)
    const now = std.time.timestamp();

    if (now < START_OF_TERM) {
        std.debug.print("The presidential term hasn't started yet.\n", .{});
        return;
    }

    const elapsed_seconds = now - START_OF_TERM;
    const total_term_seconds = END_OF_TERM - START_OF_TERM;
    const remaining_days = @divTrunc((END_OF_TERM - now), 86400);
    const percentage_fraction = @as(f32, @floatFromInt(elapsed_seconds)) / @as(f32, @floatFromInt(total_term_seconds));
    const percentage_complete = percentage_fraction * 100; // Human-readable 0-100%

    // Generate tweet text with the new format
    const tweet_text = try generateTweetText(allocator, percentage_complete, @as(i32, @intCast(remaining_days)));
    defer allocator.free(tweet_text);
    
    // Generate ASCII progress bar for display only
    const progress_bar = try generateAsciiBar(allocator, percentage_fraction);
    defer allocator.free(progress_bar);

    // Display the progress information locally
    std.debug.print("\n=== Presidential Term Progress ===\n", .{});
    std.debug.print("{s}\n", .{tweet_text});
    std.debug.print("{s}\n", .{progress_bar});
    std.debug.print("Percentage: {d:.1}%\n", .{percentage_complete});
    std.debug.print("================================\n\n", .{});
    
    // Save the progress information to a file for potential use with other services
    try saveProgressToFile(tweet_text, "progress_update.txt");
    std.debug.print("Progress information saved to progress_update.txt\n", .{});
    
    // Check if we have all the required credentials for Twitter posting
    const has_all_credentials = (api_key != null and api_secret != null and 
                                access_token != null and access_secret != null);
    
    if (has_all_credentials) {
        std.debug.print("\nTwitter API credentials are set. Would you like to post to Twitter? (y/n): ", .{});
        
        // Read user input
        const stdin = std.io.getStdIn().reader();
        var buf: [10]u8 = undefined;
        const input = try stdin.readUntilDelimiterOrEof(&buf, '\n');
        
        if (input != null and (input.?[0] == 'y' or input.?[0] == 'Y')) {
            std.debug.print("Attempting to post to Twitter using the post_tweet.sh script...\n", .{});
            
            // Use the post_tweet.sh script to post the tweet
            const result = try postTweetWithScript(allocator);
            
            if (result == 0) {
                std.debug.print("Tweet posted successfully!\n", .{});
            } else {
                std.debug.print("Failed to post tweet using the script. Exit code: {d}\n", .{result});
            }
        } else {
            std.debug.print("Not posting to Twitter. You can:\n", .{});
            std.debug.print("1. Copy the text above and post manually\n", .{});
            std.debug.print("2. Use a third-party service like IFTTT or Zapier\n\n", .{});
        }
    } else {
        std.debug.print("\nTwitter API credentials are not fully set. To post to Twitter, set up your credentials.\n", .{});
        std.debug.print("See the README for more information.\n\n", .{});
    }
}

// Saves the progress information to a file
pub fn saveProgressToFile(text: []const u8, filename: []const u8) !void {
    var file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();
    try file.writeAll(text);
}

// Generates the tweet text with the new format
pub fn generateTweetText(allocator: std.mem.Allocator, percentage: f32, remaining_days: i32) ![]const u8 {
    // Calculate the basic text summary
    const summary_text = try std.fmt.allocPrint(allocator, 
        "The Trump Presidency is {d:.1}% complete. {d} days remain.", 
        .{ percentage, remaining_days }
    );
    defer allocator.free(summary_text);
    
    // Create a GitHub-style grid visualization
    // 4 rows (years) x 12 columns (months) from inauguration to inauguration
    const rows = 4;
    const cols = 12;
    
    // Calculate how many months have fully passed since the start of the term
    const START_OF_TERM: i64 = 1737354000; // Jan 20, 2025, 12:00 PM ET (UTC)
    const END_OF_TERM: i64 = 1863622800; // Jan 20, 2029, 12:00 PM ET (UTC)
    const now = std.time.timestamp();
    const seconds_elapsed = now - START_OF_TERM;
    
    // For testing/development purposes, we need to handle the case where now < START_OF_TERM
    // In the real bot, this would be caught by the check in main()
    var adjusted_seconds_elapsed = seconds_elapsed;
    if (adjusted_seconds_elapsed < 0) {
        // For testing before the term starts, pretend we're a small percentage into the term
        adjusted_seconds_elapsed = @divTrunc(END_OF_TERM - START_OF_TERM, 34); // ~2.9% of the term
    }
    
    // Each "month" is approximately 30.44 days (365.25/12)
    const seconds_per_month = 2630016; // 30.44 days in seconds
    const months_elapsed_f = @as(f32, @floatFromInt(adjusted_seconds_elapsed)) / @as(f32, @floatFromInt(seconds_per_month));
    
    // Calculate the number of fully completed months and progress in the current month
    // Color progression for the current month:
    // 🟫 Brown: 0-25% complete
    // 🟧 Orange: 26-50% complete
    // 🟨 Yellow: 51-75% complete
    // 🟩 Green: 76-100% complete (also used for fully completed months)
    // ⬛ Black: Future months
    var full_months_elapsed: usize = 0;
    var current_month_progress: f32 = 0.0;
    
    if (percentage < 3.0) {
        // Special case for very early in the term (like 2.9%)
        // Show no completed months and the first month in progress
        full_months_elapsed = 0;
        // Set progress to 20% to ensure it shows as brown (0-25% range)
        current_month_progress = 0.2;
    } else {
        // Normal calculation for larger percentages
        full_months_elapsed = @as(usize, @intFromFloat(months_elapsed_f));
        current_month_progress = months_elapsed_f - @as(f32, @floatFromInt(full_months_elapsed));
    }
    
    // Create the grid visualization
    var grid_text = std.ArrayList(u8).init(allocator);
    defer grid_text.deinit();
    
    // Add a newline after the summary
    try grid_text.appendSlice("\n\n");
    
    // Generate the grid
    var total_months: usize = 0;
    
    for (0..rows) |row| {
        for (0..cols) |_| {
            if (total_months < full_months_elapsed) {
                // Fully completed month - always green
                try grid_text.appendSlice("🟩");
            } else if (total_months == full_months_elapsed) {
                // Current month in progress - color based on completion percentage
                if (current_month_progress < 0.25) {
                    try grid_text.appendSlice("🟫"); // 0-25% complete - brown
                } else if (current_month_progress < 0.5) {
                    try grid_text.appendSlice("🟧"); // 26-50% complete - orange
                } else if (current_month_progress < 0.75) {
                    try grid_text.appendSlice("🟨"); // 51-75% complete - yellow
                } else {
                    try grid_text.appendSlice("🟩"); // 76-100% complete - green
                }
            } else {
                // Future month - always black
                try grid_text.appendSlice("⬛");
            }
            total_months += 1;
        }
        
        // Add a newline after each row except the last one
        if (row < rows - 1) {
            try grid_text.appendSlice("\n");
        }
    }
    
    // Combine the summary and grid
    return std.fmt.allocPrint(allocator, 
        "{s}{s}", 
        .{ summary_text, grid_text.items }
    );
}

// Generates an ASCII progress bar for display
pub fn generateAsciiBar(allocator: std.mem.Allocator, percentage_fraction: f32) ![]const u8 {
    // Create an improved ASCII progress bar with 20 characters
    const bar_length = 20;
    const filled_length = @as(usize, @intFromFloat(percentage_fraction * @as(f32, @floatFromInt(bar_length))));
    
    var progress_bar = try allocator.alloc(u8, bar_length + 2); // +2 for [ and ]
    defer allocator.free(progress_bar);
    
    progress_bar[0] = '[';
    
    var i: usize = 0;
    while (i < bar_length) : (i += 1) {
        if (i < filled_length) {
            progress_bar[i + 1] = '='; // Equals sign for filled portion
        } else if (i == filled_length and filled_length > 0 and filled_length < bar_length) {
            progress_bar[i + 1] = '>'; // Arrow for the current position
        } else {
            progress_bar[i + 1] = ' '; // Space for empty portion for better contrast
        }
    }
    
    progress_bar[bar_length + 1] = ']';
    
    return std.fmt.allocPrint(allocator, "{s}", .{progress_bar});
}

// Function to post a tweet using the post_tweet.sh script
pub fn postTweetWithScript(allocator: std.mem.Allocator) !i32 {
    var child = std.process.Child.init(&[_][]const u8{"./post_tweet.sh"}, allocator);
    child.stderr_behavior = .Inherit;
    child.stdout_behavior = .Inherit;
    
    try child.spawn();
    const result = try child.wait();
    
    return switch (result) {
        .Exited => |code| code,
        else => -1,
    };
}
