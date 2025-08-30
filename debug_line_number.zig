const std = @import("std");

// Copy of the updated getSurrealLineNumber function from main.zig
pub fn getSurrealLineNumber(timestamp: i64) !usize {
    // Get days since epoch (Unix timestamp / seconds per day)
    const days_since_epoch = @divTrunc(timestamp, 86400);
    
    // Calculate the day of the week (0 = Thursday, 1 = Friday, ..., 6 = Wednesday)
    // January 1, 1970 was a Thursday, so we use modulo 7 directly
    const day_of_week = @as(usize, @intCast(@mod(days_since_epoch, 7)));
    
    // Convert to our preferred mapping (0 = Monday, 1 = Tuesday, ..., 6 = Sunday)
    var adjusted_day: usize = 0;
    if (day_of_week == 0) {
        adjusted_day = 3;      // Thursday -> 3
    } else if (day_of_week == 1) {
        adjusted_day = 4;      // Friday -> 4
    } else if (day_of_week == 2) {
        adjusted_day = 5;      // Saturday -> 5
    } else if (day_of_week == 3) {
        adjusted_day = 6;      // Sunday -> 6
    } else if (day_of_week == 4) {
        adjusted_day = 0;      // Monday -> 0
    } else if (day_of_week == 5) {
        adjusted_day = 1;      // Tuesday -> 1
    } else if (day_of_week == 6) {
        adjusted_day = 2;      // Wednesday -> 2
    }
    
    // Get the current hour
    const seconds_since_midnight = @mod(timestamp, 86400);
    const hour = @divTrunc(seconds_since_midnight, 3600);
    
    // Calculate the line number (1-indexed)
    // Each day has 2 posts (17:00 and 23:00)
    // Monday 17:00 = Line 1, Monday 23:00 = Line 2, Tuesday 17:00 = Line 3, etc.
    var line_number = adjusted_day * 2 + 1;
    
    // Adjust for the time of day
    if (hour >= 17 and hour < 23) {
        // 17:00 post - use odd-numbered lines (1, 3, 5, ...)
        // No adjustment needed
    } else {
        // 23:00 post - use even-numbered lines (2, 4, 6, ...)
        line_number += 1;
    }
    
    // Ensure we don't exceed the number of lines in the file
    // If we have 14 lines (for a full week), we can use modulo 14
    // If we have fewer lines, we'll wrap around
    return line_number;
}

pub fn getDayName(day_of_week: usize) []const u8 {
    return switch (day_of_week) {
        0 => "Monday",
        1 => "Tuesday",
        2 => "Wednesday",
        3 => "Thursday",
        4 => "Friday",
        5 => "Saturday",
        6 => "Sunday",
        else => "Unknown",
    };
}

pub fn main() !void {
    // Get the current time
    const now = std.time.timestamp();
    
    // Print the current timestamp and time
    const seconds_since_midnight = @mod(now, 86400);
    const hour = @divTrunc(seconds_since_midnight, 3600);
    const minute = @divTrunc(@mod(seconds_since_midnight, 3600), 60);
    std.debug.print("Current timestamp: {d}\n", .{now});
    std.debug.print("Current time (UTC): {d:0>2}:{d:0>2}\n", .{hour, minute});
    
    // Get days since epoch (Unix timestamp / seconds per day)
    const days_since_epoch = @divTrunc(now, 86400);
    std.debug.print("Days since epoch: {d}\n", .{days_since_epoch});
    
    // Calculate the raw day of week (0 = Thursday, 1 = Friday, ..., 6 = Wednesday)
    const raw_day_of_week = @mod(days_since_epoch, 7);
    std.debug.print("Raw day of week (0=Thu, 1=Fri, ..., 6=Wed): {d}\n", .{raw_day_of_week});
    
    // Convert to our preferred mapping (0 = Monday, 1 = Tuesday, ..., 6 = Sunday)
    var adjusted_day: usize = 0;
    if (raw_day_of_week == 0) {
        adjusted_day = 3;      // Thursday -> 3
    } else if (raw_day_of_week == 1) {
        adjusted_day = 4;      // Friday -> 4
    } else if (raw_day_of_week == 2) {
        adjusted_day = 5;      // Saturday -> 5
    } else if (raw_day_of_week == 3) {
        adjusted_day = 6;      // Sunday -> 6
    } else if (raw_day_of_week == 4) {
        adjusted_day = 0;      // Monday -> 0
    } else if (raw_day_of_week == 5) {
        adjusted_day = 1;      // Tuesday -> 1
    } else if (raw_day_of_week == 6) {
        adjusted_day = 2;      // Wednesday -> 2
    }
    
    std.debug.print("Adjusted day of week: {d} ({s})\n", .{adjusted_day, getDayName(adjusted_day)});
    
    // Get the line number for the current time
    const line_number = try getSurrealLineNumber(now);
    std.debug.print("\nSelected line number for current time: {d}\n\n", .{line_number});
    
    // Show what line numbers would be selected for each day of the week
    std.debug.print("Line numbers for each day of the week:\n", .{});
    std.debug.print("----------------------------------------\n", .{});
    
    // Create a timestamp for 17:00 and 23:00 for each day
    const seconds_17 = 17 * 3600; // 17:00 in seconds
    const seconds_23 = 23 * 3600; // 23:00 in seconds
    
    // Calculate the timestamp for the start of today
    const start_of_today = days_since_epoch * 86400;
    
    // Calculate the timestamp for the start of the week (Monday)
    const days_to_monday = if (adjusted_day == 0) 0 else 7 - adjusted_day;
    const start_of_week = start_of_today + @as(i64, @intCast(days_to_monday)) * 86400;
    
    // Show line numbers for each day of the week
    for (0..7) |i| {
        const day_timestamp = start_of_week + @as(i64, @intCast(i)) * 86400;
        const day_name = getDayName(i);
        
        // 17:00 post
        const timestamp_17 = day_timestamp + seconds_17;
        const line_17 = try getSurrealLineNumber(timestamp_17);
        
        // 23:00 post
        const timestamp_23 = day_timestamp + seconds_23;
        const line_23 = try getSurrealLineNumber(timestamp_23);
        
        std.debug.print("{s} 17:00: Line {d}\n", .{day_name, line_17});
        std.debug.print("{s} 23:00: Line {d}\n", .{day_name, line_23});
    }
} 