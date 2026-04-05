import std.conv;
import std.file;
import std.math;
import std.stdio;
import std.string;

string stddev(real[] vals, real mean) {
    if (vals.length == 0)
        return to!string(0.0);

    real sumSquares = 0.0;
    foreach (v; vals) {
        real diff = v - mean;
        sumSquares += diff * diff;
    }

    return to!string(sqrt(sumSquares / vals.length));
}

void main(string[] args) {
    if (args.length < 2 || args.length > 3)
        return;

    string[] lines = splitLines(cast(string)std.file.read(args[1]));
    real total = args.length == 2 ? 100 : to!real(args[2]);

    real wall = 0.0, user = 0.0, sys = 0.0, val;
    real[] wallVals, userVals, sysVals;

    foreach (line; lines) {
        if (line.startsWith("real")) {
            val = to!real(line[5 .. $]);
            wall += val;
            wallVals ~= val;
        } else if (line.startsWith("user")) {
            val = to!real(line[5 .. $]);
            user += val;
            userVals ~= val;
        } else if (line.startsWith("sys")) {
            val = to!real(line[4 .. $]);
            sys += val;
            sysVals ~= val;
        }
    }

    writeln("real: " ~ to!string(wall) ~ "\t avg: " ~ to!string(wall / total) ~ "\t stddev: " ~ stddev(wallVals, wall / total));
    writeln("user: " ~ to!string(user) ~ "\t avg: " ~ to!string(user / total) ~ "\t stddev: " ~ stddev(userVals, user / total));
    writeln("sys:  " ~ to!string(sys) ~ "\t avg: " ~ to!string(sys / total) ~ "\t stddev: " ~ stddev(sysVals, sys / total));
}
