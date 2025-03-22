const std = @import("std");
const builtin = @import("builtin");
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

    var state = try ent.State.Init(global_allocator, 400, .bubble);
    defer state.Deinit();

    state.Shuffle();

    raylib.SetTraceLogLevel(raylib.LOG_ERROR);
    raylib.SetTargetFPS(60);
    raylib.InitWindow(renderer.window_width, renderer.window_height, "Sorting algorithms");
    while (!raylib.WindowShouldClose()) {
        sort.Sort_One_Iteration(&state);

        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.BLACK);
        renderer.Render_Frame(&state);
        raylib.EndDrawing();
    }
}
