const std = @import("std");
const builtin = @import("builtin");
const ent = @import("entry.zig");
const raylib = @cImport({
    @cInclude("raylib.h");
});

pub const window_width = 700;
pub const window_height = 400;
pub const x_offset = 200;

pub fn Render_Frame(state: *ent.State) void {
    Update_Entry_Color_Timers(state);

    const infopanel_color = raylib.Color{
        .r = 0x10,
        .g = 0x10,
        .b = 0x10,
        .a = 255,
    };
    raylib.DrawRectangle(0, 0, x_offset, window_height, infopanel_color);
    raylib.DrawRectangle(x_offset - 3, 0, 3, window_height, raylib.DARKGRAY);

    var string_buffer: [512]u8 = undefined;
    var slice: []const u8 = undefined;
    const text_spacing = 22;

    slice = std.fmt.bufPrint(&string_buffer, "Entries: {}\x00", .{state.entry_vector.len}) catch
        @panic("buffer fmt failed");
    raylib.DrawText(slice.ptr, 5, 5 + (text_spacing * 0), 20, raylib.WHITE);

    slice = std.fmt.bufPrint(&string_buffer, "Sort: {s}\x00", .{state.current_sorting_algorithm.Get_String()}) catch
        @panic("buffer fmt failed");
    raylib.DrawText(slice.ptr, 5, 5 + (text_spacing * 1), 20, raylib.WHITE);

    slice = std.fmt.bufPrint(&string_buffer, "Compares: {}\x00", .{state.compare_counter}) catch
        @panic("buffer fmt failed");
    raylib.DrawText(slice.ptr, 5, 5 + (text_spacing * 2), 20, raylib.WHITE);

    slice = std.fmt.bufPrint(&string_buffer, "Swaps: {}\x00", .{state.swap_counter}) catch
        @panic("buffer fmt failed");
    raylib.DrawText(slice.ptr, 5, 5 + (text_spacing * 3), 20, raylib.WHITE);

    slice = std.fmt.bufPrint(&string_buffer, "Shuffles: {}\x00", .{state.shuffle_counter}) catch
        @panic("buffer fmt failed");
    raylib.DrawText(slice.ptr, 5, 5 + (text_spacing * 4), 20, raylib.WHITE);

    const rect_width: f32 = @as(f32, @floatFromInt(window_width - x_offset)) / @as(f32, @floatFromInt(state.entry_vector.len));
    var rect_height: f32 = undefined;
    for (state.entry_vector, 0..) |entry, i| {
        rect_height = @floatFromInt((window_height / state.entry_vector.len) * entry.value);
        raylib.DrawRectangle(
            // column x position
            @intFromFloat(rect_width * @as(f32, @floatFromInt(i)) + x_offset),
            // column y position
            @intFromFloat(window_height - rect_height),
            // constant column width
            @intFromFloat(@ceil(rect_width)),
            // variable column height
            @intFromFloat(rect_height),
            // column color
            Get_Entry_Color(entry));
    }
}

fn Get_Entry_Color(entry: ent.Entry) raylib.Color {
    return switch (entry.condition) {
        .neutral => Apply_Color_Shift(raylib.WHITE, entry.color_timer),
        .marked => Apply_Color_Shift(raylib.RED, entry.color_timer),
        .swapped => Apply_Color_Shift(raylib.BLUE, entry.color_timer),
        .sorted => Apply_Color_Shift(raylib.GREEN, entry.color_timer),
    };
}

fn Update_Entry_Color_Timers(state: *ent.State) void {
    const decrement = 3;
    for (state.entry_vector) |*entry| {
        if (entry.color_timer > 0) {
            if (entry.color_timer < decrement) {
                entry.color_timer = 0;
            } else {
                entry.color_timer -= decrement;
            }
        }
    }
}

fn Apply_Color_Shift(color: raylib.Color, timer: u8) raylib.Color {
    return raylib.Color{
        .a = 255,
        .r = @max(color.r, 0xFF - timer),
        .g = @max(color.g, 0xFF - timer),
        .b = @max(color.b, 0xFF - timer),
    };
}
