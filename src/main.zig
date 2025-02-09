//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

// date -d "2025-01-20 17:00:00 UTC" +%s
// 1737392400
// date -d "2029-01-20 17:00:00 UTC" +%s
// 1863622800

const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

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
    const percentage_fraction = @as(f32, elapsed_seconds) / @as(f32, total_term_seconds); // Between 0.0 - 1.0
    const percentage_complete = percentage_fraction * 100; // Now in 0-100 scale

    // Generate tweet text
    const tweet_text = try generateTweet(allocator, percentage_complete, @as(i32, @intCast(remaining_days)));
    defer allocator.free(tweet_text);

    // Generate and save SVG
    try saveSVG(allocator, "progress.svg", percentage_complete);

    // Convert SVG to PNG (requires external tool like rsvg-convert or Inkscape)
    try convertSVGtoPNG("progress.svg", "progress.png");

    // Post to Twitter
    try postToTwitter(tweet_text, "progress.png");

    std.debug.print("Percentage: {d}%\n", .{@as(i32, @intFromFloat(percentage_complete))});
    std.debug.print("Bar width: {d}px\n", .{@as(i32, @intFromFloat(percentage_complete * 380.0))});
}

// Generates the SVG progress bar dynamically
pub fn generateSVG(allocator: std.mem.Allocator, percentage: f32) ![]const u8 {
    const bar_width = @as(i32, @intFromFloat(percentage_fraction * 380.0)); // Corrected scaling

    return std.fmt.allocPrint(allocator, "<svg width=\"400\" height=\"50\" xmlns=\"http://www.w3.org/2000/svg\">\n" ++
        "    <rect width=\"400\" height=\"50\" fill=\"black\"/>\n" ++
        "    <rect width=\"380\" height=\"30\" x=\"10\" y=\"10\" fill=\"white\" stroke=\"gray\" stroke-width=\"2\"/>\n" ++
        "    <rect width=\"{d}\" height=\"30\" x=\"10\" y=\"10\" fill=\"orange\"/>\n" ++
        "    <text x=\"200\" y=\"30\" font-size=\"20\" fill=\"black\" text-anchor=\"middle\">{d}%</text>\n" ++
        "    <title>Presidential term is {d}% complete</title>\n" ++
        "</svg>\n", .{ bar_width, @as(i32, @intFromFloat(percentage)), @as(i32, @intFromFloat(percentage)) });
}

// Saves the SVG to a file
pub fn saveSVG(allocator: std.mem.Allocator, filename: []const u8, percentage: f32) !void {
    const svg = try generateSVG(allocator, percentage);
    defer allocator.free(svg);

    var file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();
    try file.writeAll(svg);
}

// Converts SVG to PNG using rsvg-convert (can use Inkscape as well)
pub fn convertSVGtoPNG(svg_file: []const u8, png_file: []const u8) !void {
    var child = std.process.Child.init(&[_][]const u8{
        "rsvg-convert", "-o", png_file, svg_file,
    }, std.heap.page_allocator);

    try child.spawn(); // Start the process

    const term = try child.wait(); // Wait for it to finish
    if (term != .Exited or term.Exited != 0) {
        std.debug.print("SVG conversion process failed.\n", .{});
        return error.ConversionFailed;
    }
}

// Generates the tweet text
pub fn generateTweet(allocator: std.mem.Allocator, percentage: f32, remaining_days: i32) ![]const u8 {
    return std.fmt.allocPrint(allocator, "Presidential term is {d}% complete. {d} days remain.", .{ @as(i32, @intFromFloat(percentage)), remaining_days });
}

// Posts the tweet with the progress bar image
pub fn postToTwitter(tweet: []const u8, image_file: []const u8) !void {
    // TODO: Implement Twitter API authentication & upload logic
    std.debug.print("Tweet: {s}\nImage: {s}\n", .{ tweet, image_file });
}
