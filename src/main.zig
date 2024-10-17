const std = @import("std");

const Grid = struct {
    width: usize,
    height: usize,
    matrix: []bool,
    tempmat: []bool,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, w: usize, h: usize) !Grid {
        return .{
            .width = w,
            .height = h,
            .matrix = try allocator.alloc(bool, w * h),
            .tempmat = try allocator.alloc(bool, w * h),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: Grid) void {
        self.allocator.free(self.matrix);
        self.allocator.free(self.tempmat);
    }

    pub fn loadState(self: *Grid, file: std.fs.File) !void {
        _ = .{ self, file };
    }

    pub fn saveState(self: Grid, file: std.fs.File) !void {
        _ = .{ self, file };
    }

    pub fn set(self: Grid, x: usize, y: usize, v: bool) void {
        const index = y * self.width + x;
        if (index >= self.matrix.len) unreachable;
        self.matrix[index] = v;
    }

    pub fn get(self: Grid, x: usize, y: usize) bool {
        const index = y * self.width + x;
        if (index >= self.matrix.len) unreachable;
        return self.matrix[index];
    }

    fn setTmp(self: Grid, x: usize, y: usize, v: bool) void {
        const index = y * self.width + x;
        if (index >= self.matrix.len) unreachable;
        self.tempmat[index] = v;
    }

    fn aliveNeighbours(self: Grid, x: usize, y: usize) usize {
        var count: usize = 0;

        var i = if (x > 0) x - 1 else x;

        while (i <= x + 1) : (i += 1) {
            var j = if (y > 0) y - 1 else y;
            while (j <= y + 1) : (j += 1) {
                if (i == x and j == y) continue;
                if (i < self.width and j < self.height and self.get(i, j))
                    count += 1;
            }
        }

        return count;
    }

    pub fn nextGeneration(self: Grid) void {
        for (0..self.width) |x| {
            for (0..self.height) |y| {
                const alive = self.get(x, y);
                const neighbors = self.aliveNeighbours(x, y);
                if (alive) {
                    if (neighbors < 2 or neighbors > 3) {
                        self.setTmp(x, y, false);
                    } else {
                        self.setTmp(x, y, true);
                    }
                } else {
                    if (neighbors == 3) {
                        self.setTmp(x, y, true);
                    } else {
                        self.setTmp(x, y, false);
                    }
                }
            }
        }
        std.mem.copyForwards(bool, self.matrix, self.tempmat);
    }

    pub fn printGeneration(self: Grid, stdout: std.fs.File) void {
        const config = std.io.tty.detectConfig(stdout);
        for (0..self.width) |x| {
            for (0..self.height) |y| {
                config.setColor(
                    stdout,
                    if (self.get(x, y)) .green else .red,
                ) catch {};
                _ = stdout.write("\xE2\x8f\xB9 ") catch continue;
            }
            if (x < self.width - 1)
                _ = stdout.write("\n") catch continue;
        }
    }
};

fn goUp(stdout: std.fs.File, count: usize) void {
    for (0..count) |_|
        _ = stdout.write("\x1b[F") catch {};
}

pub fn main() !void {
    const width = 10;
    const height = 10;
    const grid = try Grid.init(std.heap.page_allocator, width, height);
    defer grid.deinit();
    const stdout = std.io.getStdOut();

    grid.set(2, 2, true);
    grid.set(3, 2, true);
    grid.set(2, 1, true);
    grid.set(1, 6, true);
    grid.set(3, 5, true);
    grid.set(3, 6, true);
    grid.set(3, 7, true);

    while (true) {
        grid.printGeneration(stdout);
        grid.nextGeneration();
        std.time.sleep(std.time.ms_per_s * 400000);
        goUp(stdout, height);
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
