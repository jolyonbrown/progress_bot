// Presidential Term Progress Bot
// Calculates how long the current US presidency has to run and provides updates with a progress bar.

// Presidential terms begin at 12:00 PM ET on January 20th
// date -d "2025-01-20 17:00:00 UTC" +%s  # 12:00 PM ET = 17:00 UTC
// 1737392400
// date -d "2029-01-20 17:00:00 UTC" +%s  # 12:00 PM ET = 17:00 UTC
// 1863622800

const std = @import("std");

// Bluesky API credentials will be loaded from environment variables
// Set these before running the program:
// export BLUESKY_HANDLE="your_handle.bsky.social"
// export BLUESKY_APP_PASSWORD="your_app_password"

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // Load Bluesky API credentials from environment variables
    std.debug.print("Loading Bluesky API credentials from environment variables...\n", .{});

    const handle = std.process.getEnvVarOwned(allocator, "BLUESKY_HANDLE") catch |err| blk: {
        std.debug.print("Failed to get BLUESKY_HANDLE: {s}\n", .{@errorName(err)});
        break :blk null;
    };
    const app_password = std.process.getEnvVarOwned(allocator, "BLUESKY_APP_PASSWORD") catch |err| blk: {
        std.debug.print("Failed to get BLUESKY_APP_PASSWORD: {s}\n", .{@errorName(err)});
        break :blk null;
    };

    defer if (handle) |v| allocator.free(v);
    defer if (app_password) |v| allocator.free(v);

    // Print status of environment variables
    std.debug.print("Environment variables status:\n", .{});
    std.debug.print("  BLUESKY_HANDLE: {s}\n", .{if (handle != null) "Set" else "Not set"});
    std.debug.print("  BLUESKY_APP_PASSWORD: {s}\n", .{if (app_password != null) "Set" else "Not set"});

    const START_OF_TERM: i64 = 1737392400; // Jan 20, 2025, 12:00 PM ET (17:00 UTC)
    const END_OF_TERM: i64 = 1863622800; // Jan 20, 2029, 12:00 PM ET (17:00 UTC)
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

    // Generate post text with the new format
    const post_text = try generatePostText(allocator, percentage_complete, @as(i32, @intCast(remaining_days)));
    defer allocator.free(post_text);

    // Generate ASCII progress bar for display only
    const progress_bar = try generateAsciiBar(allocator, percentage_fraction);
    defer allocator.free(progress_bar);

    // Display the progress information locally
    std.debug.print("\n=== Presidential Term Progress ===\n", .{});
    std.debug.print("{s}\n", .{post_text});
    std.debug.print("{s}\n", .{progress_bar});
    std.debug.print("Percentage: {d:.2}%\n", .{percentage_complete});
    std.debug.print("================================\n\n", .{});

    // Save the progress information to a file for potential use with other services
    try saveProgressToFile(post_text, "progress_update.txt");
    std.debug.print("Progress information saved to progress_update.txt\n", .{});

    // Check if we have all the required credentials for Bluesky posting
    const has_all_credentials = (handle != null and app_password != null);

    if (has_all_credentials) {
        std.debug.print("\nBluesky API credentials are set. Would you like to post to Bluesky? (y/n): ", .{});

        // Read user input
        var stdin_buffer: [1024]u8 = undefined;
        const stdin = std.fs.File.stdin().reader(&stdin_buffer);
        var buf: [10]u8 = undefined;
        const input = stdin.readAll(&buf);

        if (input != null and (input.?[0] == 'y' or input.?[0] == 'Y')) {
            std.debug.print("Attempting to post to Bluesky using the post_bluesky.sh script...\n", .{});

            // Use the post_bluesky.sh script to post
            const result = try postBlueskyWithScript(allocator);

            if (result == 0) {
                std.debug.print("Post published successfully!\n", .{});
            } else {
                std.debug.print("Failed to post using the script. Exit code: {d}\n", .{result});
            }
        } else {
            std.debug.print("Not posting to Bluesky. You can:\n", .{});
            std.debug.print("1. Copy the text above and post manually\n", .{});
            std.debug.print("2. Use the automated script later\n\n", .{});
        }
    } else {
        std.debug.print("\nBluesky API credentials are not fully set. To post to Bluesky, set up your credentials.\n", .{});
        std.debug.print("See the README for more information.\n\n", .{});
    }
}

// Saves the progress information to a file
pub fn saveProgressToFile(text: []const u8, filename: []const u8) !void {
    var file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();
    try file.writeAll(text);
}

// Generates a surreal message using Groq API
pub fn generateSurrealMessage(allocator: std.mem.Allocator, percentage: f32, remaining_days: i32) ![]const u8 {
    std.debug.print("Generating surreal message using Groq API...\n", .{});

    // Determine time of day for context
    const now = std.time.timestamp();
    const seconds_since_midnight = @mod(now, 86400);
    const hour = @divTrunc(seconds_since_midnight, 3600);
    
    const time_of_day = if (hour >= 6 and hour < 12) 
        "morning" 
    else if (hour >= 12 and hour < 18) 
        "afternoon" 
    else if (hour >= 18 and hour < 22) 
        "evening" 
    else 
        "late_night";

    // Create argument strings
    const percentage_str = try std.fmt.allocPrint(allocator, "{d:.2}", .{percentage});
    defer allocator.free(percentage_str);
    
    const days_str = try std.fmt.allocPrint(allocator, "{d}", .{remaining_days});
    defer allocator.free(days_str);

    // Call the shell script to generate the message
    var child = std.process.Child.init(&[_][]const u8{
        "./generate_surreal_message.sh",
        percentage_str,
        days_str,
        time_of_day,
    }, allocator);
    
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    try child.spawn();
    
    const stdout_result = try child.stdout.?.readToEndAlloc(allocator, 1024);
    defer allocator.free(stdout_result);
    
    const result = try child.wait();

    switch (result) {
        .Exited => |code| {
            if (code == 0) {
                // Trim whitespace and return the message
                const trimmed = std.mem.trim(u8, stdout_result, " \t\n\r");
                if (trimmed.len > 0) {
                    std.debug.print("Generated message: {s}\n", .{trimmed});
                    return try allocator.dupe(u8, trimmed);
                } else {
                    std.debug.print("Empty response from Groq API, using fallback\n", .{});
                    return try allocator.dupe(u8, "#Trump");
                }
            } else {
                std.debug.print("Script failed with exit code: {d}\n", .{code});
                return try allocator.dupe(u8, "#Trump");
            }
        },
        else => {
            std.debug.print("Script execution failed\n", .{});
            return try allocator.dupe(u8, "#Trump");
        },
    }
}

// Generates the post text with the new format
pub fn generatePostText(allocator: std.mem.Allocator, percentage: f32, remaining_days: i32) ![]const u8 {
    // Calculate the basic text summary
    const summary_text = try std.fmt.allocPrint(allocator, "The Trump Presidency is {d:.2}% complete. {d} days remain.", .{ percentage, remaining_days });
    defer allocator.free(summary_text);

    // Create a GitHub-style grid visualization
    // 4 rows (years) x 12 columns (months) from inauguration to inauguration
    const rows = 4;
    const cols = 12;

    // Calculate how many months have fully passed since the start of the term
    const START_OF_TERM: i64 = 1737392400; // Jan 20, 2025, 12:00 PM ET (17:00 UTC)
    const END_OF_TERM: i64 = 1863622800; // Jan 20, 2029, 12:00 PM ET (17:00 UTC)
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

    // Calculate full months elapsed and progress in current month
    // Color progression for the current month:
    // 🟫 Brown: 0-25% complete
    // 🟧 Orange: 26-50% complete
    // 🟨 Yellow: 51-75% complete
    // 🟩 Green: 76-100% complete (also used for fully completed months)
    // ⬛ Black: Future months
    const full_months_elapsed = @as(usize, @intFromFloat(months_elapsed_f));
    const current_month_progress = months_elapsed_f - @as(f32, @floatFromInt(full_months_elapsed));

    // Create the grid visualization
    var grid_text: std.ArrayList(u8) = .{};
    defer grid_text.deinit(allocator);

    // Add a newline after the summary
    try grid_text.appendSlice(allocator, "\n\n");

    // Generate the grid
    var total_months: usize = 0;

    for (0..rows) |row| {
        for (0..cols) |_| {
            if (total_months < full_months_elapsed) {
                // Fully completed month - always green
                try grid_text.appendSlice(allocator, "🟩");
            } else if (total_months == full_months_elapsed) {
                // Current month in progress - color based on completion percentage
                if (current_month_progress < 0.25) {
                    try grid_text.appendSlice(allocator, "🟫"); // 0-25% complete - brown
                } else if (current_month_progress < 0.5) {
                    try grid_text.appendSlice(allocator, "🟧"); // 26-50% complete - orange
                } else if (current_month_progress < 0.75) {
                    try grid_text.appendSlice(allocator, "🟨"); // 51-75% complete - yellow
                } else {
                    try grid_text.appendSlice(allocator, "🟩"); // 76-100% complete - green
                }
            } else {
                // Future month - always black
                try grid_text.appendSlice(allocator, "⬛");
            }
            total_months += 1;
        }

        // Add a newline after each row except the last one
        if (row < rows - 1) {
            try grid_text.appendSlice(allocator, "\n");
        }
    }

    // Generate the surreal message using Groq API
    const surreal_line = try generateSurrealMessage(allocator, percentage, remaining_days);
    defer allocator.free(surreal_line);

    // Combine the summary, grid, and surreal line
    return std.fmt.allocPrint(allocator, "{s}{s}\n\n{s}", .{ summary_text, grid_text.items, surreal_line });
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

// Function to post to Bluesky using the post_bluesky.sh script
pub fn postBlueskyWithScript(allocator: std.mem.Allocator) !i32 {
    var child = std.process.Child.init(&[_][]const u8{"./post_bluesky.sh"}, allocator);
    child.stderr_behavior = .Inherit;
    child.stdout_behavior = .Inherit;

    try child.spawn();
    const result = try child.wait();

    return switch (result) {
        .Exited => |code| code,
        else => -1,
    };
}
