const std = @import("std");

pub const SortingAlgorithm = enum {
    bogo,
    insertion,
    bubble,

    pub fn Get_String(self: SortingAlgorithm) []const u8 {
        return switch (self) {
            .bogo => "Bogo",
            .insertion => "Insertion",
            .bubble => "Bubble",
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

    pub fn Set_Condition(this: *Entry, cond: EntryCondition) void {
        this.color_timer = 0xFF;
        this.condition = cond;
    }
};

pub const AuxiliarySortingVariables = struct {
    key: u32 = undefined,
    i: usize = undefined,
    j: usize = undefined,
};

pub const State = struct {
    allocator: std.mem.Allocator = undefined,
    entry_vector: []Entry = undefined,
    aux_vars: ?AuxiliarySortingVariables = null,
    is_sorted: bool = false,
    current_sorting_algorithm: SortingAlgorithm = undefined,
    compare_counter: usize = 0,
    swap_counter: usize = 0,
    shuffle_counter: usize = 0,
    write_counter: usize = 0,

    /// initialize everything, caller does not own the allocated memory
    pub fn Init(allocator: std.mem.Allocator, num: usize, algorithm: SortingAlgorithm) !State {
        var result: State = State{};
        result.allocator = allocator;
        result.entry_vector = try result.allocator.alloc(Entry, num);
        for (result.entry_vector, 1..) |*entry, i| {
            entry.value = @truncate(i);
            entry.condition = .neutral;
            entry.color_timer = 0xFF;
        }
        result.current_sorting_algorithm = algorithm;
        return result;
    }

    /// free allocated data
    pub fn Deinit(this: *State) void {
        this.allocator.free(this.entry_vector);
    }

    /// shuffle vector contents
    pub fn Shuffle(this: *State) void {
        this.shuffle_counter += 1;
        this.is_sorted = false;
        var generator = std.Random.DefaultPrng.init(@intCast(std.time.microTimestamp()));
        std.Random.shuffle(generator.random(), Entry, this.entry_vector);
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
