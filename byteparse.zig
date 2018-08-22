const std = @import("std");

/// Returns how many digits a base-10 number has.
/// Gets compiled down to many if's.
pub fn digits10(comptime N: type, n: N) usize {
    comptime var digits = 1;
    comptime var check = 10;

    inline while (check <= @maxValue(N)) : ({check *= 10; digits += 1;}) {
        if (n < check) {
            return digits;
        }
    }

    return digits;
}

const ParseError = error {
    /// The input had a byte that was not a digit
    InvalidCharacter,

    /// The result cannot fit in the type specified
    Overflow,
};

/// Returns a slice containing all the multiple powers of 10 that fit in the integer type `N`.
pub fn pow10array(comptime N: type) []N {
    comptime var multiple_of_ten: N = 1;

    comptime var table_size = comptime digits10(N, @maxValue(N));
    comptime var counter = 0;

    inline while(counter + 1 < table_size): ({counter += 1;}) {
        multiple_of_ten *= 10;
    }

    // generate table
    comptime var table: [table_size] N = undefined;

    inline for(table) |*num| {
        num.* = multiple_of_ten;
        multiple_of_ten /= 10;
    }

    return table[0..];
}

/// Converts a byte-slice into the integer type `N`.
/// if the byte-slice contains a digit that is not valid, an error is returned.
/// An empty slice returns 0.
pub fn atoi(comptime N: type, buf: []const u8) ParseError!N {

    comptime var table = comptime pow10array(N);

    if (buf.len > table.len) {
        return ParseError.Overflow;
    }

    var bytes = buf;
    var result: N = 0;
    var len = buf.len;
    var idx = table.len - len;

    while (len >= 4) {
        comptime var UNROLL_COUNT = 0;

        // unroll
        inline while(UNROLL_COUNT < 4): ({UNROLL_COUNT += 1;}) {
            var r1 = bytes[UNROLL_COUNT] -% 48;
            if (r1 > 9) {
                return ParseError.InvalidCharacter;
            }
            var d1: N = r1 * table[idx + UNROLL_COUNT]; 
            result = result +% d1;
        }

        len -= 4;
        idx += 4;

        bytes = bytes[4..];
    }

   
    for (bytes) |byte, offset| {
        var r = byte -% 48;
        if (r > 9) {
            return ParseError.InvalidCharacter;
        }

        var d: N = r * table[idx + offset];
        result = result +% d;
    }

    return result;
}

test "digits10" {
    @import("std").debug.assert(digits10(u1, 1) == 1);
    @import("std").debug.assert(digits10(u2, 3) == 1);
    @import("std").debug.assert(digits10(u8, 255) == 3);
}

test "atoi" {
    const assert = std.debug.assert;

    assert((atoi(u64, "18446744073709551615") catch 0) == 18446744073709551615);
    
    // catch a string with a non-digit character
    assert((atoi(u64, "1234e") catch 0) == 0);

    // overflow
    assert((atoi(u8, "257") catch 0) == 1);

    assert((atoi(u32, "9876543") catch 0) == 9876543);

    // parse more digits than the type can handle
    assert((atoi(u8, "1000") catch 0) == 0);
}

pub fn main() void {
    var n: u16 = 10;
    var s = digits10(u16, n);

    std.debug.assert(s == 2);

    var foo = digits10(usize, 10000);

    std.debug.assert(foo == 5);

    var parsed = comptime atoi(u64, "257") catch 0;

    std.debug.warn("{}\n", parsed);
}