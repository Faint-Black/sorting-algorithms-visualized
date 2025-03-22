const std = @import("std");
const ent = @import("entry.zig");

pub fn Sort_One_Iteration(state: *ent.State) void {
    if (state.is_sorted)
        return;

    switch (state.current_sorting_algorithm) {
        .bogo => Bogo_Sort(state),
        .insertion => Insertion_Sort(state),
        .bubble => Bubble_Sort(state),
    }

    if (state.is_sorted)
        state.Set_All_Conditions_To(.sorted);
}

fn Bogo_Sort(state: *ent.State) void {
    // init "local" variables
    if (state.aux_vars == null) {
        state.aux_vars = ent.AuxiliarySortingVariables{
            .i = 1,
        };
    }
    const aux: *ent.AuxiliarySortingVariables = &state.aux_vars.?;

    // reached solved state
    if (aux.i >= state.entry_vector.len) {
        state.is_sorted = true;
        return;
    }

    const i = aux.i;
    // if NOT sorted, shuffle and reset counter
    if (state.Compare(i - 1, i, ent.State.Predicate) == false) {
        state.Set_All_Conditions_To(.neutral);
        state.Shuffle();
        aux.i = 0;
    }

    aux.i += 1;
}

fn Insertion_Sort(state: *ent.State) void {
    // init "local" variables
    if (state.aux_vars == null) {
        state.aux_vars = ent.AuxiliarySortingVariables{
            .i = 1,
            .j = 1,
        };
    }
    const aux: *ent.AuxiliarySortingVariables = &state.aux_vars.?;

    if (aux.i >= state.entry_vector.len) {
        state.is_sorted = true;
        return;
    }

    if ((aux.j > 0) and state.Compare(aux.j, aux.j - 1, ent.State.Predicate)) {
        state.Swap(aux.j, aux.j - 1);
        aux.j -= 1;
    } else {
        aux.i += 1;
        aux.j = aux.i;
    }
}

fn Bubble_Sort(state: *ent.State) void {
    // init "local" variables
    if (state.aux_vars == null) {
        state.aux_vars = ent.AuxiliarySortingVariables{
            .i = 1, // will serve as (rhs) index of a comparison pair
            .j = state.entry_vector.len, // will serve as the iteration count
        };
    }
    const i: *usize = &state.aux_vars.?.i;
    const max: *usize = &state.aux_vars.?.j;

    if (max.* <= 2) {
        state.is_sorted = true;
        return;
    }

    if (i.* >= max.*) {
        i.* = 1;
        max.* -= 1;
    }

    if (state.Compare(i.* - 1, i.*, ent.State.Predicate) == false) {
        state.Swap(i.* - 1, i.*);
    }

    i.* += 1;
}
