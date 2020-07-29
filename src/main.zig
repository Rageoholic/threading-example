const std = @import("std");

// Zig's threading lib lets us pass an arbitrary parameter into our
// thread procedure. So let's make one with all the stuff we need
const ThreadInfo = struct {
    id: usize,
    // The stdlib doesn't lock around stdout so... yeah we need this
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

    // Create the lock we will use around stdout
    var stdout_lock = std.Mutex.init();

    // Iterate over the number of threads we intend to spawn
    for (threads) |*thread, i| {
        // cons up the info we need for the thread into a struct
        const thread_info = ThreadInfo{ .id = i, .stdout_lock = &stdout_lock };

        // Spawn the thread
        thread.* = try std.Thread.spawn(thread_info, threadProc);
    }

    // When you spawn threads you have to wait on them to complete
    // before exiting or else you're going to cut them off in the
    // middle of their work
    for (threads) |thread| {
        thread.wait();
    }
}
