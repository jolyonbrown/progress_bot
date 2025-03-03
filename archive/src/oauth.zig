const std = @import("std");
const c = @cImport({
    @cInclude("stddef.h");  // For size_t
    @cInclude("stdlib.h");  // For malloc, free
    @cInclude("oauth.h");
    @cInclude("curl/curl.h");
});

pub const OAuthError = error{
    MissingCredentials,
    SignatureGenerationFailed,
    RequestFailed,
    ResponseParsingFailed,
    MemoryAllocationFailed,
};

pub const OAuthCredentials = struct {
    consumer_key: []const u8,
    consumer_secret: []const u8,
    access_token: []const u8,
    access_token_secret: []const u8,
};

/// Initialize OAuth credentials from environment variables
pub fn initCredentialsFromEnv(allocator: std.mem.Allocator) !OAuthCredentials {
    const api_key = std.process.getEnvVarOwned(allocator, "TWITTER_API_KEY") catch |err| {
        std.debug.print("Failed to get TWITTER_API_KEY: {s}\n", .{@errorName(err)});
        return OAuthError.MissingCredentials;
    };
    errdefer allocator.free(api_key);

    const api_secret = std.process.getEnvVarOwned(allocator, "TWITTER_API_SECRET") catch |err| {
        std.debug.print("Failed to get TWITTER_API_SECRET: {s}\n", .{@errorName(err)});
        allocator.free(api_key);
        return OAuthError.MissingCredentials;
    };
    errdefer allocator.free(api_secret);

    const access_token = std.process.getEnvVarOwned(allocator, "TWITTER_ACCESS_TOKEN") catch |err| {
        std.debug.print("Failed to get TWITTER_ACCESS_TOKEN: {s}\n", .{@errorName(err)});
        allocator.free(api_key);
        allocator.free(api_secret);
        return OAuthError.MissingCredentials;
    };
    errdefer allocator.free(access_token);

    const access_secret = std.process.getEnvVarOwned(allocator, "TWITTER_ACCESS_SECRET") catch |err| {
        std.debug.print("Failed to get TWITTER_ACCESS_SECRET: {s}\n", .{@errorName(err)});
        allocator.free(api_key);
        allocator.free(api_secret);
        allocator.free(access_token);
        return OAuthError.MissingCredentials;
    };

    return OAuthCredentials{
        .consumer_key = api_key,
        .consumer_secret = api_secret,
        .access_token = access_token,
        .access_token_secret = access_secret,
    };
}

/// Free memory allocated for OAuth credentials
pub fn freeCredentials(allocator: std.mem.Allocator, credentials: OAuthCredentials) void {
    allocator.free(credentials.consumer_key);
    allocator.free(credentials.consumer_secret);
    allocator.free(credentials.access_token);
    allocator.free(credentials.access_token_secret);
}

/// Callback function for libcurl to write response data
fn curlWriteCallback(ptr: *anyopaque, size: c_uint, nmemb: c_uint, data: *anyopaque) callconv(.C) c_uint {
    const real_size = size * nmemb;
    const buffer = @as(*std.ArrayList(u8), @ptrCast(@alignCast(data)));
    
    const slice = @as([*]u8, @ptrCast(ptr))[0..real_size];
    buffer.appendSlice(slice) catch return 0;
    
    return real_size;
}

/// Post a tweet using OAuth 1.0a authentication
pub fn postTweet(allocator: std.mem.Allocator, credentials: OAuthCredentials, tweet_text: []const u8) ![]const u8 {
    // URL for posting tweets (using v1.1 API)
    const url = "https://api.twitter.com/1.1/statuses/update.json";
    
    // Create URL-encoded payload for v1.1 API
    const encoded_tweet = try urlEncode(allocator, tweet_text);
    defer allocator.free(encoded_tweet);
    
    const status_param = try std.fmt.allocPrint(allocator, "status={s}", .{encoded_tweet});
    defer allocator.free(status_param);
    
    // Debug output
    std.debug.print("Status parameter: {s}\n", .{status_param});
    
    // Generate OAuth header with status parameter included in the signature
    const oauth_header = try generateOAuthHeaderWithStatus(
        allocator,
        credentials,
        "POST",
        url,
        tweet_text
    );
    defer allocator.free(oauth_header);
    
    // Initialize CURL
    const curl = c.curl_easy_init();
    if (curl == null) {
        return OAuthError.RequestFailed;
    }
    defer c.curl_easy_cleanup(curl);
    
    // Set up response buffer
    var response_buffer = std.ArrayList(u8).init(allocator);
    defer response_buffer.deinit();
    
    // Set CURL options
    _ = c.curl_easy_setopt(curl, c.CURLOPT_URL, url.ptr);
    _ = c.curl_easy_setopt(curl, c.CURLOPT_POST, @as(c_long, 1));
    _ = c.curl_easy_setopt(curl, c.CURLOPT_POSTFIELDS, status_param.ptr);
    _ = c.curl_easy_setopt(curl, c.CURLOPT_POSTFIELDSIZE, @as(c_long, @intCast(status_param.len)));
    _ = c.curl_easy_setopt(curl, c.CURLOPT_WRITEFUNCTION, curlWriteCallback);
    _ = c.curl_easy_setopt(curl, c.CURLOPT_WRITEDATA, &response_buffer);
    
    // Force HTTP/1.1 to avoid HTTP/2 framing layer issues
    _ = c.curl_easy_setopt(curl, c.CURLOPT_HTTP_VERSION, c.CURL_HTTP_VERSION_1_1);
    
    // Enable verbose output for debugging
    _ = c.curl_easy_setopt(curl, c.CURLOPT_VERBOSE, @as(c_long, 1));
    
    // Set headers
    const oauth_header_c = try allocator.dupeZ(u8, oauth_header);
    defer allocator.free(oauth_header_c);
    
    const content_type = "Content-Type: application/x-www-form-urlencoded";
    const content_type_c = try allocator.dupeZ(u8, content_type);
    defer allocator.free(content_type_c);
    
    var headers = c.curl_slist_append(null, oauth_header_c.ptr);
    headers = c.curl_slist_append(headers, content_type_c.ptr);
    defer c.curl_slist_free_all(headers);
    _ = c.curl_easy_setopt(curl, c.CURLOPT_HTTPHEADER, headers);
    
    // Perform request
    const res = c.curl_easy_perform(curl);
    if (res != c.CURLE_OK) {
        std.debug.print("CURL request failed: {s}\n", .{c.curl_easy_strerror(res)});
        return OAuthError.RequestFailed;
    }
    
    // Get HTTP status code
    var status_code: c_long = 0;
    _ = c.curl_easy_getinfo(curl, c.CURLINFO_RESPONSE_CODE, &status_code);
    
    // Check status code
    if (status_code != 200 and status_code != 201) {
        std.debug.print("HTTP error: {d}\n", .{status_code});
        std.debug.print("Response: {s}\n", .{response_buffer.items});
        
        switch (status_code) {
            401 => {
                std.debug.print("Authentication failed. Check your OAuth credentials.\n", .{});
            },
            403 => {
                std.debug.print("Authorization failed. Check your app permissions.\n", .{});
            },
            429 => {
                std.debug.print("Rate limit exceeded. Try again later.\n", .{});
            },
            else => {
                std.debug.print("Unexpected error. Check the response for details.\n", .{});
            },
        }
        
        return OAuthError.RequestFailed;
    }
    
    // Return the response
    return response_buffer.toOwnedSlice();
}

/// URL-encode a string
pub fn urlEncode(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();

    for (input) |char| {
        if (std.ascii.isAlphanumeric(char) or char == '-' or char == '.' or char == '_' or char == '~') {
            try result.append(char);
        } else {
            try result.writer().print("%{X:0>2}", .{char});
        }
    }

    return result.toOwnedSlice();
}

/// Compare two strings for sorting
fn stringLessThan(_: void, a: []const u8, b: []const u8) bool {
    return std.mem.lessThan(u8, a, b);
}

/// Generate a random nonce for OAuth
fn generateNonce(allocator: std.mem.Allocator) ![]const u8 {
    var random_bytes: [8]u8 = undefined;
    std.crypto.random.bytes(&random_bytes);
    
    // Convert to base64
    const base64_size = std.base64.standard.Encoder.calcSize(random_bytes.len);
    const base64_buf = try allocator.alloc(u8, base64_size);
    errdefer allocator.free(base64_buf);
    
    _ = std.base64.standard.Encoder.encode(base64_buf, &random_bytes);
    
    // Remove non-alphanumeric characters
    var clean_nonce = std.ArrayList(u8).init(allocator);
    errdefer clean_nonce.deinit();
    
    for (base64_buf) |char| {
        if (std.ascii.isAlphanumeric(char)) {
            try clean_nonce.append(char);
        }
    }
    
    allocator.free(base64_buf);
    return clean_nonce.toOwnedSlice();
}

/// Generate OAuth 1.0a header with status parameter included in the signature
fn generateOAuthHeaderWithStatus(
    allocator: std.mem.Allocator,
    credentials: OAuthCredentials,
    method: []const u8,
    url: []const u8,
    status_text: []const u8,
) ![]const u8 {
    // Generate nonce
    const nonce = try generateNonce(allocator);
    defer allocator.free(nonce);
    
    // Get timestamp
    const timestamp = try std.fmt.allocPrint(allocator, "{d}", .{std.time.timestamp()});
    defer allocator.free(timestamp);
    
    // Build Authorization header
    var header = std.ArrayList(u8).init(allocator);
    errdefer header.deinit();
    
    try header.appendSlice("Authorization: OAuth ");
    
    // Add parameters to header
    const params_to_add = [_]struct { name: []const u8, value: []const u8 }{
        .{ .name = "oauth_consumer_key", .value = credentials.consumer_key },
        .{ .name = "oauth_nonce", .value = nonce },
        .{ .name = "oauth_signature_method", .value = "HMAC-SHA1" },
        .{ .name = "oauth_timestamp", .value = timestamp },
        .{ .name = "oauth_token", .value = credentials.access_token },
        .{ .name = "oauth_version", .value = "1.0" },
    };
    
    // Create base string for signature
    var base_string = std.ArrayList(u8).init(allocator);
    defer base_string.deinit();
    
    try base_string.appendSlice(method);
    try base_string.append('&');
    const encoded_url = try urlEncode(allocator, url);
    defer allocator.free(encoded_url);
    try base_string.appendSlice(encoded_url);
    try base_string.append('&');
    
    // Build parameter string including status
    var param_string = std.ArrayList(u8).init(allocator);
    defer param_string.deinit();
    
    // Add OAuth parameters
    var all_params = std.ArrayList([]const u8).init(allocator);
    defer {
        for (all_params.items) |param| {
            allocator.free(param);
        }
        all_params.deinit();
    }
    
    // Add OAuth parameters
    try all_params.append(try std.fmt.allocPrint(allocator, "oauth_consumer_key={s}", .{credentials.consumer_key}));
    try all_params.append(try std.fmt.allocPrint(allocator, "oauth_nonce={s}", .{nonce}));
    try all_params.append(try std.fmt.allocPrint(allocator, "oauth_signature_method={s}", .{"HMAC-SHA1"}));
    try all_params.append(try std.fmt.allocPrint(allocator, "oauth_timestamp={s}", .{timestamp}));
    try all_params.append(try std.fmt.allocPrint(allocator, "oauth_token={s}", .{credentials.access_token}));
    try all_params.append(try std.fmt.allocPrint(allocator, "oauth_version={s}", .{"1.0"}));
    
    // Add status parameter
    const encoded_status = try urlEncode(allocator, status_text);
    defer allocator.free(encoded_status);
    try all_params.append(try std.fmt.allocPrint(allocator, "status={s}", .{encoded_status}));
    
    // Sort parameters
    std.sort.heap([]const u8, all_params.items, {}, stringLessThan);
    
    // Build parameter string
    for (all_params.items, 0..) |param, i| {
        if (i > 0) try param_string.append('&');
        try param_string.appendSlice(param);
    }
    
    const encoded_params = try urlEncode(allocator, param_string.items);
    defer allocator.free(encoded_params);
    try base_string.appendSlice(encoded_params);
    
    // Debug output
    std.debug.print("Base string with status: {s}\n", .{base_string.items});
    
    // Create signing key
    const signing_key = try std.fmt.allocPrint(allocator, "{s}&{s}", 
        .{credentials.consumer_secret, credentials.access_token_secret});
    defer allocator.free(signing_key);
    
    // Generate signature
    const signature_c = c.oauth_sign_hmac_sha1(base_string.items.ptr, signing_key.ptr);
    if (signature_c == null) return OAuthError.SignatureGenerationFailed;
    const signature = std.mem.span(signature_c);
    defer c.free(signature_c);
    
    // Add parameters to header
    for (params_to_add, 0..) |param, i| {
        if (i > 0) try header.appendSlice(", ");
        
        const encoded_value = try urlEncode(allocator, param.value);
        defer allocator.free(encoded_value);
        
        try header.writer().print("{s}=\"{s}\"", .{ param.name, encoded_value });
    }
    
    // Add signature
    const encoded_signature = try urlEncode(allocator, signature);
    defer allocator.free(encoded_signature);
    
    try header.writer().print(", oauth_signature=\"{s}\"", .{encoded_signature});
    
    return header.toOwnedSlice();
}

/// Post a tweet using a Bearer token (API v2)
pub fn postTweetWithBearer(allocator: std.mem.Allocator, bearer_token: []const u8, tweet_text: []const u8) ![]const u8 {
    // URL for posting tweets (using v2 API)
    const url = "https://api.twitter.com/2/tweets";
    
    // Create JSON payload
    var json_buffer = std.ArrayList(u8).init(allocator);
    defer json_buffer.deinit();
    
    try json_buffer.appendSlice("{\"text\":\"");
    
    // Escape special characters in the tweet text
    for (tweet_text) |char| {
        switch (char) {
            '\\' => try json_buffer.appendSlice("\\\\"),
            '\"' => try json_buffer.appendSlice("\\\""),
            '\n' => try json_buffer.appendSlice("\\n"),
            '\r' => try json_buffer.appendSlice("\\r"),
            else => try json_buffer.append(char),
        }
    }
    
    try json_buffer.appendSlice("\"}");
    
    const payload = try json_buffer.toOwnedSlice();
    defer allocator.free(payload);
    
    // Debug output
    std.debug.print("Bearer token payload: {s}\n", .{payload});
    std.debug.print("Bearer token payload length: {d}\n", .{payload.len});
    
    // Initialize CURL
    const curl = c.curl_easy_init();
    if (curl == null) {
        return OAuthError.RequestFailed;
    }
    defer c.curl_easy_cleanup(curl);
    
    // Set up response buffer
    var response_buffer = std.ArrayList(u8).init(allocator);
    defer response_buffer.deinit();
    
    // Set CURL options
    _ = c.curl_easy_setopt(curl, c.CURLOPT_URL, url.ptr);
    _ = c.curl_easy_setopt(curl, c.CURLOPT_POST, @as(c_long, 1));
    _ = c.curl_easy_setopt(curl, c.CURLOPT_POSTFIELDS, payload.ptr);
    _ = c.curl_easy_setopt(curl, c.CURLOPT_POSTFIELDSIZE, @as(c_long, @intCast(payload.len)));
    _ = c.curl_easy_setopt(curl, c.CURLOPT_WRITEFUNCTION, curlWriteCallback);
    _ = c.curl_easy_setopt(curl, c.CURLOPT_WRITEDATA, &response_buffer);
    
    // Force HTTP/1.1 to avoid HTTP/2 framing layer issues
    _ = c.curl_easy_setopt(curl, c.CURLOPT_HTTP_VERSION, c.CURL_HTTP_VERSION_1_1);
    
    // Enable verbose output for debugging
    _ = c.curl_easy_setopt(curl, c.CURLOPT_VERBOSE, @as(c_long, 1));
    
    // Set headers
    const auth_header = try std.fmt.allocPrint(allocator, "Authorization: Bearer {s}", .{bearer_token});
    defer allocator.free(auth_header);
    
    const auth_header_c = try allocator.dupeZ(u8, auth_header);
    defer allocator.free(auth_header_c);
    
    const content_type = "Content-Type: application/json";
    const content_type_c = try allocator.dupeZ(u8, content_type);
    defer allocator.free(content_type_c);
    
    var headers = c.curl_slist_append(null, auth_header_c.ptr);
    headers = c.curl_slist_append(headers, content_type_c.ptr);
    defer c.curl_slist_free_all(headers);
    _ = c.curl_easy_setopt(curl, c.CURLOPT_HTTPHEADER, headers);
    
    // Perform request
    const res = c.curl_easy_perform(curl);
    if (res != c.CURLE_OK) {
        std.debug.print("CURL request failed: {s}\n", .{c.curl_easy_strerror(res)});
        return OAuthError.RequestFailed;
    }
    
    // Get HTTP status code
    var status_code: c_long = 0;
    _ = c.curl_easy_getinfo(curl, c.CURLINFO_RESPONSE_CODE, &status_code);
    
    // Check status code
    if (status_code != 200 and status_code != 201) {
        std.debug.print("HTTP error: {d}\n", .{status_code});
        std.debug.print("Response: {s}\n", .{response_buffer.items});
        
        switch (status_code) {
            401 => {
                std.debug.print("Authentication failed. Check your Bearer token.\n", .{});
            },
            403 => {
                std.debug.print("Authorization failed. Check your app permissions.\n", .{});
            },
            429 => {
                std.debug.print("Rate limit exceeded. Try again later.\n", .{});
            },
            else => {
                std.debug.print("Unexpected error. Check the response for details.\n", .{});
            },
        }
        
        return OAuthError.RequestFailed;
    }
    
    // Return the response
    return response_buffer.toOwnedSlice();
} 