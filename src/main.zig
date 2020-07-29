const std = @import("std");

const ThreadInfo = struct {
    id: usize,
    stdout_lock: *std.Mutex,
};

fn threadProc(thread_info: ThreadInfo) !void {
    var i = @as(usize, 0);
    while (i < 4) {
        {
            const held = thread_info.stdout_lock.acquire();
            defer held.release();
            const stdout = std.io.getStdOut().writer();
            try stdout.print("Thread {} on iteration {}\n", .{ thread_info.id, i });
        }
        i += 1;

        std.time.sleep(1000000000);
    }
}

pub fn main() anyerror!void {
    var threads: [4]*std.Thread = undefined;
    var stdout_lock = std.Mutex.init();
    for (threads) |*thread, i| {
        const thread_info = ThreadInfo{ .id = i, .stdout_lock = &stdout_lock };
        thread.* = try std.Thread.spawn(thread_info, threadProc);
    }
    for (threads) |thread| {
        thread.wait();
    }
}
