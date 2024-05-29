const std = @import("std");
const cli = @import("cli.zig");
const http = std.http;
const heap = std.heap;

const Client = http.Client;
const RequestOptions = Client.RequestOptions;

const Todo = struct {
    userId: usize,
    id: usize,
    title: []const u8,
    completed: bool,
};

const FetchReq = struct {
    const Self = @This();
    const Allocator = std.mem.Allocator;

    allocator: Allocator,
    client: std.http.Client,
    body: std.ArrayList(u8),

    pub fn init(allocator: Allocator) Self {
        const c = Client{ .allocator = allocator };
        return Self{
            .allocator = allocator,
            .client = c,
            .body = std.ArrayList(u8).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.client.deinit();
        self.body.deinit();
    }

    /// Blocking
    pub fn get(self: *Self, url: []const u8, headers: []http.Header) !Client.FetchResult {
        const fetch_options = Client.FetchOptions{
            .location = Client.FetchOptions.Location{
                .url = url,
            },
            .extra_headers = headers,
            .response_storage = .{ .dynamic = &self.body },
        };

        const res = try self.client.fetch(fetch_options);
        return res;
    }
};

const FileError = error{};
// TODO: Better error handling, windows
// WARN: Windows not handled
fn creatFile(name: []const u8, content: []const u8) !bool {
    const file = try std.fs.cwd().createFile(name, .{});
    defer file.close();
    std.log.info("Creating .gitignore", .{});
    const bytes_written = try file.writeAll(content);
    _ = bytes_written;
    std.log.info("Sucessfully written", .{});

    return true;
}

pub fn main() !void {
    // get args
    var gpa_impl = heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa_impl.deinit() == .leak) {
        std.log.warn("Has leaked\n", .{});
    };

    const gpa = gpa_impl.allocator();

    var req = FetchReq.init(gpa);
    defer req.deinit();

    const cli_args = try cli.getCliArgs();

    std.debug.print("{s}\n", .{cli_args});
    // GET request
    {
        std.log.info("creating url", .{});
        // const get_url = "https://www.toptal.com/developers/gitignore/api/" ++ cli_args;
        const get_url = std.fmt.allocPrint(gpa, "https://www.toptal.com/developers/gitignore/api/{s}", .{cli_args}) catch "format failed";
        defer gpa.free(get_url);
        std.log.info("free memory for url", .{});
        const res = try req.get(get_url, &.{});
        const body = try req.body.toOwnedSlice();
        defer req.allocator.free(body);

        if (res.status != .ok) {
            std.log.err("GET request failed - {s}\n", .{body});
        }

        _ = try creatFile(".gitignore", body);

        // const parsed = try std.json.parseFromSlice(Todo, gpa, body, .{});
        // defer parsed.deinit();

        // const todo = Todo{
        //     .userId = parsed.value.userId,
        //     .id = parsed.value.id,
        //     .title = parsed.value.title,
        //     .completed = parsed.value.completed,
        // };
        // std.debug.print("{s}", .{body});
        // std.debug.print(
        //     \\ GET response body struct -
        //     \\ user ID - {d}
        //     \\ id {d}
        //     \\ title {s}
        //     \\ completed {}
        //     \\
        // , .{ todo.userId, todo.id, todo.title, todo.completed });
    }
}
