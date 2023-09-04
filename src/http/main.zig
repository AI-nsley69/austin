const std = @import("std");
const server = @import("server.zig");

pub fn run() !void {
    // Memory allocator setup
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const server_addr: []const u8 = "127.0.0.1";
    const server_port: u16 = 8080;
    var srv = try server.create(server_addr, server_port, allocator);
    defer srv.deinit();

    try server.run(&srv, allocator);
}
