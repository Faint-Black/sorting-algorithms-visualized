//=============================================================//
//                                                             //
//                          RENDERER                           //
//                                                             //
//   Responsible for dealing with anything Raylib related,     //
//  including the keyboard input handling.                     //
//                                                             //
//=============================================================//

const std = @import("std");
const builtin = @import("builtin");
const ent = @import("entry.zig");
const clap = @import("clap.zig");
const raylib = @cImport({
    @cInclude("raylib.h");
});

pub const window_width = 720;
pub const window_height = 480;
pub const x_offset = 200;

pub fn Handle_Inputs(state: *ent.State, flags: *clap.Flags) void {
    if (raylib.IsKeyPressed(raylib.KEY_R)) {
        state.Reset();
    }
    if (raylib.IsKeyDown(raylib.KEY_UP)) {
        flags.iterations_per_second += 1;
    }
    if (raylib.IsKeyDown(raylib.KEY_DOWN)) {
        if (flags.iterations_per_second > 1)
            flags.iterations_per_second -= 1;
    }
    if (raylib.IsKeyPressed(raylib.KEY_RIGHT)) {
        state.Change_Sort(state.current_sorting_algorithm.Cycle_Next(true));
    }
    if (raylib.IsKeyPressed(raylib.KEY_LEFT)) {
        state.Change_Sort(state.current_sorting_algorithm.Cycle_Next(false));
    }
}

pub fn Render_Frame(state: *ent.State, flags: *clap.Flags) void {
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

    const diagonal_offset: i32 = 5;
    const text_spacing: i32 = 22;
    var text_line_counter: i32 = 0;

    slice = std.fmt.bufPrint(&string_buffer, "[{s}]\x00", .{state.current_sorting_algorithm.Get_String()}) catch
        @panic("buffer fmt failed");
    raylib.DrawText(slice.ptr, 5, diagonal_offset + (text_spacing * text_line_counter), 20, raylib.WHITE);
    text_line_counter += 1;

    slice = std.fmt.bufPrint(&string_buffer, "Entries: {}\x00", .{state.entry_vector.len}) catch
        @panic("buffer fmt failed");
    raylib.DrawText(slice.ptr, 5, diagonal_offset + (text_spacing * text_line_counter), 20, raylib.WHITE);
    text_line_counter += 1;

    slice = std.fmt.bufPrint(&string_buffer, "Iterations/s: {}\x00", .{flags.iterations_per_second}) catch
        @panic("buffer fmt failed");
    raylib.DrawText(slice.ptr, 5, diagonal_offset + (text_spacing * text_line_counter), 20, raylib.WHITE);
    text_line_counter += 2;

    slice = std.fmt.bufPrint(&string_buffer, "Iteration: {}\x00", .{state.iteration_counter}) catch
        @panic("buffer fmt failed");
    raylib.DrawText(slice.ptr, 5, diagonal_offset + (text_spacing * text_line_counter), 20, raylib.WHITE);
    text_line_counter += 1;

    slice = std.fmt.bufPrint(&string_buffer, "Shuffles: {}\x00", .{state.shuffle_counter}) catch
        @panic("buffer fmt failed");
    raylib.DrawText(slice.ptr, 5, diagonal_offset + (text_spacing * text_line_counter), 20, raylib.WHITE);
    text_line_counter += 1;

    slice = std.fmt.bufPrint(&string_buffer, "Compares: {}\x00", .{state.compare_counter}) catch
        @panic("buffer fmt failed");
    raylib.DrawText(slice.ptr, 5, diagonal_offset + (text_spacing * text_line_counter), 20, raylib.RED);
    text_line_counter += 1;

    slice = std.fmt.bufPrint(&string_buffer, "Swaps: {}\x00", .{state.swap_counter}) catch
        @panic("buffer fmt failed");
    raylib.DrawText(slice.ptr, 5, diagonal_offset + (text_spacing * text_line_counter), 20, raylib.BLUE);
    text_line_counter += 9;

    raylib.DrawText("(R) reset", 5, diagonal_offset + (text_spacing * text_line_counter), 20, raylib.WHITE);
    text_line_counter += 1;
    raylib.DrawText("(<-) previous sort", 5, diagonal_offset + (text_spacing * text_line_counter), 20, raylib.WHITE);
    text_line_counter += 1;
    raylib.DrawText("(->) next sort", 5, diagonal_offset + (text_spacing * text_line_counter), 20, raylib.WHITE);
    text_line_counter += 1;
    raylib.DrawText("(UP) +ips", 5, diagonal_offset + (text_spacing * text_line_counter), 20, raylib.WHITE);
    text_line_counter += 1;
    raylib.DrawText("(DOWN) -ips", 5, diagonal_offset + (text_spacing * text_line_counter), 20, raylib.WHITE);
    text_line_counter += 1;

    const rect_width: f32 = @as(f32, @floatFromInt(window_width - x_offset)) / @as(f32, @floatFromInt(state.entry_vector.len));
    for (state.entry_vector, 0..) |entry, i| {
        const rect_height_scalar: f32 = window_height / @as(f32, @floatFromInt(state.entry_vector.len));
        const rect_height: f32 = rect_height_scalar * @as(f32, @floatFromInt(entry.value));
        raylib.DrawRectangle(
            // column x position
            @intFromFloat(rect_width * @as(f32, @floatFromInt(i)) + x_offset),
            // column y position
            @intFromFloat(window_height - rect_height + 1),
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
