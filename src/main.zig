const std = @import("std");
const zigsys = @import("zigsys");

pub fn main() !void {
    var file = try std.fs.cwd().createFile("./hello.txt", .{ .read = false, .truncate = true });
    defer file.close();

    const BUFFER_SIZE: usize = 10 * 1024;
    var writeBuffer: [BUFFER_SIZE]u8 = undefined;
    var writer = file.writer(&writeBuffer);

    const allocator = std.heap.c_allocator;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    for (args) |arg| try writer.interface.print("{s}\n", .{arg});
    try writer.interface.flush();

    // Wait for a timer bsd
    const kq = std.c.kqueue();
    if(kq == -1) {
        std.c.exit(kq);
    }
    defer _ = std.c.close(kq); // TODO is this the right close?

    const timer_seconds = 5;

    const change_event : std.c.Kevent = .{
        .ident = 1,
        .filter = std.c.EVFILT.TIMER,
        .flags = std.c.EV.ENABLE | std.c.EV.ADD,
        .data = timer_seconds * 1000,
        .fflags = 0, // not used here
        .udata = 0,
    };
    const change_events = [_]std.c.Kevent {change_event};

    var triggered_event : [1]std.c.Kevent = undefined;

    std.debug.print("Registering a {d} second timer with kqueue and waiting...\n", .{timer_seconds});

    const num_events = std.c.kevent(kq, &change_events, 1, &triggered_event, 1, null);

    std.debug.print("Received {d} events ...\n", .{num_events});
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

// test "fuzz example" {
//     const Context = struct {
//         fn testOne(context: @This(), input: []const u8) anyerror!void {
//             _ = context;
//             // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
//             try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
//         }
//     };
//     try std.testing.fuzz(Context{}, Context.testOne, .{});
// }
