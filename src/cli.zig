const std = @import("std");

pub fn getCliArgs() ![]const u8 {
    const alloc = std.heap.page_allocator;

    var args = try std.process.argsWithAllocator(alloc);
    defer args.deinit();

    _ = args.skip();

    var buffer = std.ArrayList(u8).init(alloc);
    defer buffer.deinit();

    while (args.next()) |arg| {
        if (buffer.items.len > 0) {
            try buffer.append(',');
        }

        try buffer.appendSlice(arg);
    }

    return buffer.toOwnedSlice();
}
