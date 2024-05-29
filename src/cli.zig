const std = @import("std");

pub fn getCliArgs() ![]const u8 {
    const alloc = std.heap.page_allocator;

    var args = try std.process.argsWithAllocator(alloc);
    defer args.deinit();

    _ = args.skip();

    if (!args.skip()) {
        std.log.info("no arguments, cancelling...", .{});
        std.process.exit(5);
        return error.NoArguments;
    }
    var buffer = std.ArrayList(u8).init(alloc);
    defer buffer.deinit();

    // var argsCount: i32 = 0;

    while (args.next()) |arg| {
        if (buffer.items.len > 0) {
            try buffer.append(',');
        }

        try buffer.appendSlice(arg);
    }

    return buffer.toOwnedSlice();
}
