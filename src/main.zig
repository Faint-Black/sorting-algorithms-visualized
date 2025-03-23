const std = @import("std");
const builtin = @import("builtin");
const clap = @import("clap.zig");
const ent = @import("entry.zig");
const renderer = @import("render.zig");
const sort = @import("sorts.zig");
const raylib = @cImport({
    @cInclude("raylib.h");
});

pub fn main() !void {
    var backing_allocator = std.heap.DebugAllocator(.{}).init;
    defer _ = backing_allocator.deinit();
    const global_allocator = backing_allocator.allocator();

    var flags = try clap.Flags.Parse(global_allocator);
    if (flags.help) {
        std.debug.print(clap.Flags.Help_String(), .{});
        return;
    }
    if (flags.version) {
        std.debug.print(clap.Flags.Version_String(), .{});
        return;
    }

    var state = try ent.State.Init(global_allocator, flags.entry_count, flags.starting_sort);
    defer state.Deinit();
    state.Shuffle();

    var iters_per_frame: f64 = undefined;
    var frametime_count: f64 = 0.0;

    raylib.SetTraceLogLevel(raylib.LOG_ERROR);
    raylib.SetTargetFPS(60);
    raylib.InitWindow(renderer.window_width, renderer.window_height, "Sorting algorithms");
    while (!raylib.WindowShouldClose()) {
        iters_per_frame = @as(f64, @floatFromInt(flags.iterations_per_second)) / 60.0;

        if (frametime_count >= 1.0) {
            frametime_count -= 1.0;
            sort.Sort_One_Iteration(&state);
            continue;
        } else {
            frametime_count += iters_per_frame;
        }

        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.BLACK);
        renderer.Handle_Inputs(&state, &flags);
        renderer.Render_Frame(&state, &flags);
        raylib.EndDrawing();
    }
}
