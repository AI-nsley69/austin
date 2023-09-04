const std = @import("std");
const http = @import("http/main.zig");

pub fn main() !void {
    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("HELLO WORLD!!!11\n", .{});

    try bw.flush(); // don't forget to flush!

    try http.run();
}
