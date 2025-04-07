//=============================================================//
//                                                             //
//                     SORTING ALGORITHMS                      //
//                                                             //
//   Defines the single iteration version of the sorting       //
//  algorithms.                                                //
//                                                             //
//=============================================================//

const std = @import("std");
const ent = @import("entry.zig");

pub fn Sort_One_Iteration(state: *ent.State) void {
    if (state.is_sorted)
        return;

    state.iteration_counter += 1;
    switch (state.current_sorting_algorithm) {
        .bogo => Bogo_Sort(state),
        .insertion => Insertion_Sort(state),
        .bubble => Bubble_Sort(state),
        .selection => Selection_Sort(state),
    }

    if (state.is_sorted)
        state.Set_All_Conditions_To(.sorted);
}

fn Bogo_Sort(state: *ent.State) void {
    // init "local" variables
    // Space complexity = O(1)
    if (state.aux_vars == null) {
        state.aux_vars = .{
            .satisfies_predicate = false,
            .allocated_index_array = state.allocator.alloc(usize, 1) catch @panic("Memory allocation error!"),
            .allocated_value_array = null,
        };
        // i = 1
        state.aux_vars.?.allocated_index_array.?[0] = 1;
    }
    const i = &state.aux_vars.?.allocated_index_array.?[0];

    // reached solved state
    if (i.* >= state.entry_vector.len) {
        state.is_sorted = true;
        return;
    }

    // if NOT sorted, shuffle and reset counter
    if (state.Compare(i.* - 1, i.*, ent.State.Predicate) == false) {
        state.Set_All_Conditions_To(.neutral);
        state.Shuffle();
        return;
    }

    i.* += 1;
}

fn Insertion_Sort(state: *ent.State) void {
    // init "local" variables
    // Space complexity = O(2)
    if (state.aux_vars == null) {
        state.aux_vars = .{
            .satisfies_predicate = false,
            .allocated_index_array = state.allocator.alloc(usize, 2) catch @panic("Memory allocation error!"),
            .allocated_value_array = null,
        };
        // i = 1
        state.aux_vars.?.allocated_index_array.?[0] = 1;
        // j = 1
        state.aux_vars.?.allocated_index_array.?[1] = 1;
    }
    const pred = &state.aux_vars.?.satisfies_predicate;
    const i = &state.aux_vars.?.allocated_index_array.?[0];
    const j = &state.aux_vars.?.allocated_index_array.?[1];

    if (i.* >= state.entry_vector.len) {
        state.is_sorted = true;
        return;
    }

    // comparisons and swaps do not occur on the same iteration
    if (pred.*) {
        state.Swap(j.*, j.* - 1);
        j.* -= 1;
        pred.* = false;
        return;
    }

    // skip redundant iteration
    if (j.* == 0) {
        i.* += 1;
        j.* = i.*;
        if (i.* >= state.entry_vector.len) {
            state.is_sorted = true;
            return;
        }
    }

    if (state.Compare(j.*, j.* - 1, ent.State.Predicate)) {
        pred.* = true;
    } else {
        i.* += 1;
        j.* = i.*;
    }
}

fn Bubble_Sort(state: *ent.State) void {
    // init "local" variables
    // Space complexity = O(2)
    if (state.aux_vars == null) {
        state.aux_vars = .{
            .satisfies_predicate = false,
            .allocated_index_array = state.allocator.alloc(usize, 2) catch @panic("Memory allocation error!"),
            .allocated_value_array = null,
        };
        // i = 1
        state.aux_vars.?.allocated_index_array.?[0] = 1;
        // max = len
        state.aux_vars.?.allocated_index_array.?[1] = state.entry_vector.len;
    }
    const pred = &state.aux_vars.?.satisfies_predicate;
    const i = &state.aux_vars.?.allocated_index_array.?[0];
    const max = &state.aux_vars.?.allocated_index_array.?[1];

    if (max.* <= 1) {
        state.is_sorted = true;
        return;
    }

    // comparisons and swaps do not occur on the same iteration
    if (pred.*) {
        state.Swap(i.* - 2, i.* - 1);
        pred.* = false;
        return;
    }

    if (i.* >= max.*) {
        i.* = 1;
        max.* -= 1;
    }

    if (state.Compare(i.* - 1, i.*, ent.State.Predicate) == false) {
        pred.* = true;
    }

    i.* += 1;
}

fn Selection_Sort(state: *ent.State) void {
    // init "local" variables
    // Space complexity = O(3)
    if (state.aux_vars == null) {
        state.aux_vars = .{
            .satisfies_predicate = false,
            .allocated_index_array = state.allocator.alloc(usize, 3) catch @panic("Memory allocation error!"),
            .allocated_value_array = null,
        };
        // slow = 0
        state.aux_vars.?.allocated_index_array.?[0] = 0;
        // fast = 0
        state.aux_vars.?.allocated_index_array.?[1] = 0;
        // smallest = undefined
        state.aux_vars.?.allocated_index_array.?[2] = 0;
    }
    const slow = &state.aux_vars.?.allocated_index_array.?[0];
    const fast = &state.aux_vars.?.allocated_index_array.?[1];
    const smallest = &state.aux_vars.?.allocated_index_array.?[2];

    if ((slow.* + 1) >= state.entry_vector.len) {
        state.is_sorted = true;
        return;
    }

    fast.* += 1;

    // fast index reached end of list, swap with lowest then reset
    if (fast.* >= state.entry_vector.len) {
        state.Swap(slow.*, smallest.*);
        slow.* += 1;
        fast.* = slow.*;
        smallest.* = slow.*;
        return;
    }

    if (state.Compare(smallest.*, fast.*, ent.State.Predicate) == false) {
        smallest.* = fast.*;
    }
}
