const std = @import("std");
const zigsys = @import("zigsys");
const uv = @cImport(@cInclude("uv.h"));

// Writing the file arguments to a file
fn create_file() void {
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
}

// Waiting for a timer with kqueue
fn kqueue_wait() void {
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

fn timer_callback(handle : *uv.uv_timer_t) callconv(.c) void {
    std.debug.print("Timer has fired! Now we can do our work.\n", .{});

    // If you're done with the timer, close it.
    uv.uv_close(@ptrCast(handle), null);
}

// wait for a timer using libuv
fn libuv_timer() void {
    const loop: *uv.uv_loop_t = uv.uv_default_loop();
    var my_timer : uv.uv_timer_t = undefined;
    _ = uv.uv_timer_init(loop, &my_timer); 
    std.debug.print("Starting a 3-second timer...\n", .{});

    _ = uv.uv_timer_start(&my_timer, @ptrCast(&timer_callback), 3000, 0);

    _ = uv.uv_run(loop, uv.UV_RUN_DEFAULT);

    std.debug.print("Event loop has finished.\n", .{});
    
    // Clean up the loop
    _ = uv.uv_loop_close(loop);
}

pub fn main() !void {
    std.debug.print("hello world\n", .{});
    libuv_timer();
}

// test "simple test" {
//     const gpa = std.testing.allocator;
//     var list: std.ArrayList(i32) = .empty;
//     defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
//     try list.append(gpa, 42);
//     try std.testing.expectEqual(@as(i32, 42), list.pop());
// }

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
