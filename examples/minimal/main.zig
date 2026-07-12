const std = @import("std");
const quickjs = @import("quickjs");

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(init.io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    // Initialize the JavaScript runtime
    const rt: *quickjs.Runtime = try .init();
    defer rt.deinit();

    // Create a JavaScript context
    const ctx: *quickjs.Context = try .init(rt);
    defer ctx.deinit();

    // Evaluate JavaScript code
    const result = ctx.eval(
        \\const greeting = "Hello from QuickJS!";
        \\const numbers = [1, 2, 3, 4, 5];
        \\const sum = numbers.reduce((a, b) => a + b, 0);
        \\`${greeting} Sum of 1-5 is ${sum}`
    , "<example>", .{});
    defer result.deinit(ctx);

    // Check for errors
    if (result.isException()) {
        const exc = ctx.getException();
        defer exc.deinit(ctx);
        if (exc.toCString(ctx)) |msg| {
            defer ctx.freeCString(msg);
            std.debug.print("Error: {s}\n", .{msg});
        } else {
            std.debug.print("Error: unknown error\n", .{});
        }
        return error.JavaScriptException;
    }

    // Extract the result as a string
    const str = result.toCString(ctx) orelse return error.NotAString;
    defer ctx.freeCString(str);

    try stdout.print("{s}\n", .{str});
    try stdout.flush();
}
