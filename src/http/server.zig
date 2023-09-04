const std = @import("std");
const http = std.http;
const log = std.log.scoped(.server);

pub fn create(addr: []const u8, port: u16, allocator: std.mem.Allocator) !http.Server {
    var server = http.Server.init(allocator, .{ .reuse_address = true });
    errdefer server.deinit();

    log.info("Server is running at {s}:{d}", .{ addr, port });

    const address = std.net.Address.parseIp(addr, port) catch unreachable;
    try server.listen(address);

    return server;
}

pub fn run(server: *http.Server, allocator: std.mem.Allocator) !void {
    runServer(server, allocator) catch |err| {
        log.err("server error: {}\n", .{err});
        if (@errorReturnTrace()) |trace| {
            std.debug.dumpStackTrace(trace.*);
        }
        std.os.exit(1);
    };
}

fn runServer(server: *http.Server, allocator: std.mem.Allocator) !void {
    outer: while (true) {
        var response = try server.accept(.{
            .allocator = allocator,
        });
        defer response.deinit();

        while (response.reset() != .closing) {
            response.wait() catch |err| switch (err) {
                error.HttpHeadersInvalid => continue :outer,
                error.EndOfStream => continue,
                else => return err,
            };

            try handleRequest(&response);
        }
    }
}

fn handleRequest(response: *http.Server.Response) !void {
    log.info("{s} {s} {s}", .{ @tagName(response.request.method), @tagName(response.request.version), response.request.target });

    if (response.request.headers.contains("connection")) {
        try response.headers.append("connection", "keep-alive");
    }

    if (std.mem.startsWith(u8, response.request.target, "/")) {
        const response_string = "Hello World!\n";
        // Check if the request target contains "?chunked".
        if (std.mem.indexOf(u8, response.request.target, "?chunked") != null) {
            response.transfer_encoding = .chunked;
        } else {
            response.transfer_encoding = .{ .content_length = response_string.len };
        }

        try response.headers.append("content-type", "text/plain");
        try response.do();
        if (response.request.method != .HEAD) {
            try response.writeAll(response_string);
            try response.finish();
        }
    } else {
        response.status = .not_found;
        try response.do();
    }
}
