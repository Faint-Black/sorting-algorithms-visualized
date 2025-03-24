//=============================================================//
//                                                             //
//            COMMAND LINE ARGUMENTS PARSER                    //
//                                                             //
//   Responsible for setting the flags passed through the      //
//  command line terminal.                                     //
//                                                             //
//=============================================================//

const std = @import("std");
const ent = @import("entry.zig");

pub const Flags = struct {
    iterations_per_second: usize = 60,
    entry_count: usize = 100,
    starting_sort: ent.SortingAlgorithm = .insertion,
    help: bool = false,
    version: bool = false,

    pub fn Parse(allocator: std.mem.Allocator) !Flags {
        var result = Flags{};

        // parsing loop
        var argv = try std.process.ArgIterator.initWithAllocator(allocator);
        defer argv.deinit();
        var arg: ?[:0]const u8 = argv.next();
        while (arg != null) {
            defer arg = argv.next();

            if (std.mem.eql(u8, "-h", arg.?) or std.mem.eql(u8, "--help", arg.?))
                result.help = true;
            if (std.mem.eql(u8, "-v", arg.?) or std.mem.eql(u8, "--version", arg.?))
                result.version = true;
            if (std.mem.eql(u8, "--sort=bogo", arg.?))
                result.starting_sort = .bogo;
            if (std.mem.eql(u8, "--sort=insertion", arg.?))
                result.starting_sort = .insertion;
            if (std.mem.eql(u8, "--sort=bubble", arg.?))
                result.starting_sort = .bubble;
            if (std.mem.startsWith(u8, arg.?, "--count="))
                result.entry_count = std.fmt.parseInt(usize, arg.?[8..], 10) catch 100;
            if (std.mem.startsWith(u8, arg.?, "--ips="))
                result.iterations_per_second = std.fmt.parseInt(usize, arg.?[6..], 10) catch 60;
        }

        // invalid flag value checks
        if (result.iterations_per_second == 0)
            return error.BadIPS;
        if (result.entry_count <= 5)
            return error.CountTooLow;

        return result;
    }

    pub fn Help_String() []const u8 {
        return 
        \\The sorting algorithm visualizer.
        \\
        \\USAGE:
        \\$ ./sorts-visualized
        \\$ ./sorts-visualized --sort=bubble --ips=10 --count=100
        \\
        \\INFO FLAGS:
        \\-h, --help
        \\    Output this text.
        \\-v, --version
        \\    Output the version information of this program.
        \\
        \\CORE USAGE FLAGS:
        \\--count=[int]
        \\    Specify number of columns to be sorted. Default is 100.
        \\--ips=[int]
        \\    Specify rate of algorithm iterations per second. Default is 60.
        \\--sort=[sorting-algorithm]
        \\    Specify the sorting algorithm to be used. Default is insertion sort.
        \\
        \\AVAILABLE SORTING ALGORITHMS:
        \\bogo, insertion, bubble
        \\
        ;
    }

    pub fn Version_String() []const u8 {
        return 
        \\The sorting algorithm visualizer.
        \\Version 0.2
        \\
        ;
    }
};
