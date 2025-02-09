//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");

// date -d "2025-01-20 17:00:00 UTC" +%s
// 1737392400
// date -d "2029-01-20 17:00:00 UTC" +%s
// 1863622800

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    // Fixed start time of the presidency (Jan 20, 2025, 12:00 PM ET in UTC)
    const START_OF_TERM: i64 = 1737354000;

    // Fixed start time of the presidency (Jan 20, 2025, 12:00 PM ET in UTC)
    const END_OF_TERM: i64 = 1863622800;

    // Get current time
    const now = std.time.timestamp();

    // Compute total seconds
    const total_seconds = END_OF_TERM - START_OF_TERM;

    // Compute elapsed seconds
    const elapsed_seconds = now - START_OF_TERM;

    // Convert to days
    const elapsed_days = @divTrunc(elapsed_seconds, 86400);

    try stdout.print("Days since term started: {d}\n", .{elapsed_days});

    // Compute remaining seconds
    const remaining_seconds = END_OF_TERM - now;

    // Convert to days
    const remaining_days = @divTrunc(remaining_seconds, 86400);

    try stdout.print("Days till term ends: {d}\n", .{remaining_days});

    // Compute percentage in seconds
    const percentage_complete = @divTrunc((elapsed_seconds * 100), total_seconds);

    try stdout.print("Percentage complete: {d}\n", .{percentage_complete});
}
