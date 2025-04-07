//=============================================================//
//                                                             //
//                           ENTRY                             //
//                                                             //
//   Defines the behaviour of the columns and values to be     //
//  sorted, as well as defining the global program's state     //
//  machine.                                                   //
//                                                             //
//=============================================================//

const std = @import("std");
const clap = @import("clap.zig");

pub const SortingAlgorithm = enum {
    bogo,
    insertion,
    bubble,
    selection,

    pub fn Get_String(self: SortingAlgorithm) []const u8 {
        return switch (self) {
            .bogo => "Bogo",
            .insertion => "Insertion",
            .bubble => "Bubble",
            .selection => "Selection",
        };
    }

    /// bogo sort is *not* included in the cycle
    pub fn Cycle_Next(self: SortingAlgorithm, next_or_previous: bool) SortingAlgorithm {
        if (next_or_previous) {
            return switch (self) {
                .bogo => .insertion,

                .insertion => .bubble,
                .bubble => .selection,
                .selection => .insertion,
            };
        } else {
            return switch (self) {
                .bogo => .insertion,

                .insertion => .selection,
                .bubble => .insertion,
                .selection => .bubble,
            };
        }
    }
};

pub const ShuffleType = enum {
    random,
    worst_case,
    mostly_sorted,

    pub fn Get_String(self: ShuffleType) []const u8 {
        return switch (self) {
            .random => "Random Shuffle",
            .worst_case => "Worst Case",
            .mostly_sorted => "Mostly Sorted",
        };
    }
};

pub const EntryCondition = enum {
    neutral,
    marked,
    swapped,
    sorted,
};

pub const Entry = struct {
    value: u32,
    condition: EntryCondition,
    color_timer: u8,

    /// automatically adjusts timer
    pub fn Set_Condition(this: *Entry, cond: EntryCondition) void {
        this.color_timer = 0xFF;
        this.condition = cond;
    }
};

pub const AuxiliarySortingVariables = struct {
    satisfies_predicate: bool = undefined,
    allocated_index_array: ?[]usize = null,
    allocated_value_array: ?[]u32 = null,

    pub fn Deinit(self: AuxiliarySortingVariables, allocator: std.mem.Allocator) void {
        if (self.allocated_index_array) |memory|
            allocator.free(memory);
        if (self.allocated_value_array) |memory|
            allocator.free(memory);
    }
};

pub const State = struct {
    allocator: std.mem.Allocator = undefined,

    entry_vector: []Entry = undefined,
    aux_vars: ?AuxiliarySortingVariables = null,
    is_sorted: bool = false,
    current_sorting_algorithm: SortingAlgorithm = undefined,
    current_shuffle_type: ShuffleType = undefined,
    mostly_sorted_range: usize = undefined,
    iteration_counter: usize = 0,
    compare_counter: usize = 0,
    swap_counter: usize = 0,
    shuffle_counter: usize = 0,
    write_counter: usize = 0,

    /// initialize everything and allocates the entries data
    pub fn Init(allocator: std.mem.Allocator, flags: clap.Flags) !State {
        var result: State = State{};
        result.allocator = allocator;
        result.entry_vector = try result.allocator.alloc(Entry, flags.entry_count);
        for (result.entry_vector, 1..) |*entry, i| {
            entry.value = @truncate(i);
            entry.condition = .neutral;
            entry.color_timer = 0xFF;
        }
        result.current_sorting_algorithm = flags.starting_sort;
        result.current_shuffle_type = flags.shuffle_type;
        result.mostly_sorted_range = flags.mostly_sorted_range;
        return result;
    }

    /// free allocated data
    pub fn Deinit(this: *State) void {
        if (this.aux_vars) |aux|
            aux.Deinit(this.allocator);
        this.allocator.free(this.entry_vector);
    }

    /// reset variables to starting values then shuffle vector
    pub fn Reset(this: *State) void {
        if (this.aux_vars) |aux|
            aux.Deinit(this.allocator);
        this.aux_vars = null;
        this.is_sorted = false;
        this.iteration_counter = 0;
        this.compare_counter = 0;
        this.swap_counter = 0;
        this.write_counter = 0;

        this.Shuffle();
    }

    /// shuffle vector and reset aux variables
    pub fn Shuffle(this: *State) void {
        if (this.aux_vars) |aux|
            aux.Deinit(this.allocator);
        this.aux_vars = null;
        this.shuffle_counter += 1;
        this.is_sorted = false;

        switch (this.current_shuffle_type) {
            .random => {
                var generator = std.Random.DefaultPrng.init(@intCast(std.time.microTimestamp()));
                std.Random.shuffle(generator.random(), Entry, this.entry_vector);
            },
            .worst_case => {
                for (0..this.entry_vector.len) |i| {
                    this.entry_vector[i].value = @truncate(this.entry_vector.len - i);
                }
            },
            .mostly_sorted => {
                var generator = std.Random.DefaultPrng.init(@intCast(std.time.microTimestamp()));
                if ((this.mostly_sorted_range + 1) >= this.entry_vector.len) {
                    // just do a random sort if range is higher than vector length
                    std.Random.shuffle(generator.random(), Entry, this.entry_vector);
                } else {
                    for (0..this.entry_vector.len - this.mostly_sorted_range) |i|
                        std.Random.shuffle(generator.random(), Entry, this.entry_vector[i .. i + this.mostly_sorted_range]);
                }
            },
        }
    }

    /// safely change sorting algorithm
    pub fn Change_Sort(this: *State, new_sort: SortingAlgorithm) void {
        if (this.aux_vars) |aux|
            aux.Deinit(this.allocator);
        this.aux_vars = null;
        this.current_sorting_algorithm = new_sort;
    }

    /// ascending order sorting predicate for higher order functions
    pub fn Predicate(a: u32, b: u32) bool {
        return a < b;
    }

    /// sort interface function
    /// compares order of two entries
    pub fn Compare(this: *State, index_a: usize, index_b: usize, predicate: fn (u32, u32) bool) bool {
        this.compare_counter += 1;
        this.entry_vector[index_a].Set_Condition(.marked);
        this.entry_vector[index_b].Set_Condition(.marked);
        return predicate(this.entry_vector[index_a].value, this.entry_vector[index_b].value);
    }

    /// sort interface function
    /// compares order of an entry and an immediate value
    pub fn Compare_Value(this: *State, index: usize, value: u32, predicate: fn (u32, u32) bool) bool {
        this.compare_counter += 1;
        this.entry_vector[index].Set_Condition(.marked);
        return predicate(this.entry_vector[index].value, value);
    }

    /// sort interface function
    /// swaps the position of two entries
    pub fn Swap(this: *State, index_a: usize, index_b: usize) void {
        this.swap_counter += 1;
        this.entry_vector[index_a].Set_Condition(.swapped);
        this.entry_vector[index_b].Set_Condition(.swapped);
        std.mem.swap(Entry, &this.entry_vector[index_a], &this.entry_vector[index_b]);
    }

    /// sort interface function
    /// overwrites the entry content with an immediate value
    pub fn Write(this: *State, index: usize, value: u32) void {
        this.write_counter += 1;
        this.entry_vector[index].Set_Condition(.swapped);
        this.entry_vector[index].value = value;
    }

    /// sort interface function
    pub fn Set_All_Conditions_To(this: *State, cond: EntryCondition) void {
        for (this.entry_vector) |*entry| {
            entry.Set_Condition(cond);
        }
    }
};
