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

    var bytes = buf;
    var result: N = 0;
    var len = buf.len;
    var idx = table.len - len;

    while (len >= 4) {
        var r1 = bytes[0] -% 48;
        if (r1 > 9) {
            return ParseError.InvalidCharacter;
        }
        var d1 = r1 * table[idx];

        var r2 = bytes[1] -% 48;
        if (r2 > 9) {
            return ParseError.InvalidCharacter;
        }
        var d2 = r2 * table[idx + 1];

        var r3 = bytes[2] -% 48;
        if (r3 > 9) {
            return ParseError.InvalidCharacter;
        }
        var d3 = r3 * table[idx + 2];

        var r4 = bytes[3] -% 48;
        if (r4 > 9) {
            return ParseError.InvalidCharacter;
        }
        var d4 = r4 * table[idx + 3];

        result = result +% (d1 + d2 + d3 + d4);

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